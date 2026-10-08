import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/protocol.dart';
import '../utils/ansi_styles.dart';
import '../utils/config.dart';
import 'chat_server.dart';

/// Manages server lifecycle (start foreground/daemon, stop, status).
class ServerManager {
  /// Starts server in foreground.
  static Future<void> startForeground({
    String host = AppConfig.defaultHost,
    int port = AppConfig.defaultPort,
  }) async {
    await runZonedGuarded(() async {
      final server = ChatServer(host: host, port: port);
      await server.start();

      // Write PID file
      AppConfig.pidFile.writeAsStringSync('$pid\n$host\n$port');

      // Handle termination signals
      try {
        ProcessSignal.sighup.watch().listen((_) {});
      } catch (_) {}

      ProcessSignal.sigint.watch().listen((_) async {
        stdout.writeln('\n${TerminalStyle.warning('Đang dừng server...')}');
        await server.stop();
        _cleanupPid();
        exit(0);
      });

      ProcessSignal.sigterm.watch().listen((_) async {
        stdout.writeln(
          '\n${TerminalStyle.warning('Đã nhận tín hiệu dừng server...')}',
        );
        await server.stop();
        _cleanupPid();
        exit(0);
      });

      // Keep foreground running
      final completer = Completer<void>();
      await completer.future;
    }, (error, stack) {
      if (error is! SocketException) {
        stderr.writeln('${TerminalStyle.error('[Server Error]')} $error');
      }
    });
  }

  /// Starts server in daemon (background) mode.
  static Future<bool> startDaemon({
    String host = AppConfig.defaultHost,
    int port = AppConfig.defaultPort,
    String? executablePath,
  }) async {
    final status = await checkStatus(host: host, port: port);
    if (status.isRunning) {
      stdout.writeln(
        '${TerminalStyle.warning('⚠️ Server đã đang chạy trên')} $host:$port (PID: ${status.pid ?? 'unknown'})',
      );
      return false;
    }

    final exec = executablePath ?? Platform.resolvedExecutable;
    List<String> args;

    // Check if running via dart or compiled binary
    if (exec.endsWith('dart') || exec.endsWith('dart.exe')) {
      final script = Platform.script.toFilePath();
      args = [
        'run',
        script,
        'server',
        'start',
        '--host',
        host,
        '--port',
        port.toString(),
      ];
    } else {
      args = ['server', 'start', '--host', host, '--port', port.toString()];
    }

    final logFile = AppConfig.serverLogFile;

    try {
      final logPath = logFile.path;
      final commandStr =
          'setsid "$exec" ${args.map((a) => '"$a"').join(' ')} >> "$logPath" 2>&1 & echo \$!';
      final result = await Process.run('sh', ['-c', commandStr]);
      final startedPid = int.tryParse(result.stdout.toString().trim());

      if (startedPid != null) {
        AppConfig.pidFile.writeAsStringSync('$startedPid\n$host\n$port');
      }

      // Wait briefly and verify socket is up
      await Future.delayed(const Duration(milliseconds: 500));
      final check = await checkStatus(host: host, port: port);

      if (check.isRunning) {
        stdout.writeln(
          TerminalStyle.success('✔ Server daemon đã được khởi động ngầm thành công!'),
        );
        stdout.writeln('${TerminalStyle.primary('  PID:     ')} ${check.pid ?? startedPid}');
        stdout.writeln('${TerminalStyle.primary('  Địa chỉ: ')} $host:$port');
        stdout.writeln('${TerminalStyle.primary('  Log:     ')} ${logFile.path}');
        return true;
      } else {
        stderr.writeln(
          TerminalStyle.error('Không thể xác nhận server đang hoạt động. Vui lòng kiểm tra log: ${logFile.path}'),
        );
        return false;
      }
    } catch (e) {
      stderr.writeln('${TerminalStyle.error('Lỗi khởi động daemon:')} $e');
      return false;
    }
  }

  /// Stops a running server daemon.
  static Future<bool> stopServer() async {
    final status = await checkStatus();
    if (!status.isRunning) {
      stdout.writeln(TerminalStyle.mute('ℹ Không có server nào đang chạy.'));
      _cleanupPid();
      return true;
    }

    if (status.pid != null) {
      try {
        Process.killPid(status.pid!, ProcessSignal.sigterm);
        _cleanupPid();
        stdout.writeln(
          TerminalStyle.success(
            '✔ Đã dừng server (PID: ${status.pid}) thành công!',
          ),
        );
        return true;
      } catch (e) {
        stderr.writeln(
          '${TerminalStyle.error('Không thể dừng PID ${status.pid}:')} $e',
        );
        return false;
      }
    } else {
      stderr.writeln(TerminalStyle.warning('Không tìm thấy PID của server.'));
      return false;
    }
  }

  /// Probes the server status.
  static Future<ServerStatusInfo> checkStatus({String? host, int? port}) async {
    int? recordedPid;
    String targetHost = host ?? AppConfig.defaultHost;
    int targetPort = port ?? AppConfig.defaultPort;

    if (AppConfig.pidFile.existsSync()) {
      try {
        final lines = AppConfig.pidFile.readAsLinesSync();
        if (lines.isNotEmpty) {
          recordedPid = int.tryParse(lines[0].trim());
        }
        if (host == null && lines.length > 1) {
          targetHost = lines[1].trim();
        }
        if (port == null && lines.length > 2) {
          targetPort = int.tryParse(lines[2].trim()) ?? targetPort;
        }
      } catch (_) {}
    }

    try {
      final socket = await Socket.connect(
        targetHost,
        targetPort,
        timeout: const Duration(seconds: 2),
      );
      final completer = Completer<Map<String, dynamic>?>();

      // Send status_req
      socket.write('${Packet.statusReq().encode()}\n');

      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              final packet = Packet.tryParse(line);
              if (packet != null && packet.type == PacketType.statusRes) {
                if (!completer.isCompleted) completer.complete(packet.data);
              }
            },
            onError: (_) {
              if (!completer.isCompleted) completer.complete(null);
            },
            onDone: () {
              if (!completer.isCompleted) completer.complete(null);
            },
            cancelOnError: true,
          );

      final data = await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      socket.destroy();

      return ServerStatusInfo(
        isRunning: true,
        pid: recordedPid,
        host: targetHost,
        port: targetPort,
        metadata: data,
      );
    } catch (_) {
      // Socket failed to connect
      return ServerStatusInfo(
        isRunning: false,
        pid: recordedPid,
        host: targetHost,
        port: targetPort,
      );
    }
  }

  static void _cleanupPid() {
    try {
      if (AppConfig.pidFile.existsSync()) {
        AppConfig.pidFile.deleteSync();
      }
    } catch (_) {}
  }
}

class ServerStatusInfo {
  final bool isRunning;
  final int? pid;
  final String host;
  final int port;
  final Map<String, dynamic>? metadata;

  ServerStatusInfo({
    required this.isRunning,
    this.pid,
    required this.host,
    required this.port,
    this.metadata,
  });
}
