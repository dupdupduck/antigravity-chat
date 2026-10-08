import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../server/server_manager.dart';
import '../utils/ansi_styles.dart';
import '../utils/config.dart';

/// Command to manage the Antigravity Chat Server.
class ServerCommand extends Command<int> {
  @override
  final String name = 'server';

  @override
  final String description =
      'Khởi chạy hoặc quản lý Terminal Chat Server riêng của Antigravity.';

  ServerCommand() {
    addSubcommand(ServerStartCommand());
    addSubcommand(ServerStopCommand());
    addSubcommand(ServerStatusCommand());
  }

  @override
  Future<int> run() async {
    printUsage();
    return ExitCode.usage.code;
  }
}

class ServerStartCommand extends Command<int> {
  @override
  final String name = 'start';

  @override
  final String description = 'Khởi động terminal server.';

  ServerStartCommand() {
    argParser
      ..addOption(
        'host',
        abbr: 'H',
        defaultsTo: AppConfig.defaultHost,
        help: 'Địa chỉ bind server (mặc định: 127.0.0.1)',
      )
      ..addOption(
        'port',
        abbr: 'p',
        defaultsTo: AppConfig.defaultPort.toString(),
        help: 'Cổng lắng nghe (mặc định: 4040)',
      )
      ..addFlag(
        'daemon',
        abbr: 'd',
        defaultsTo: false,
        help: 'Chạy server ngầm dưới dạng tiến trình nền (daemon)',
      );
  }

  @override
  Future<int> run() async {
    final host = argResults?['host'] as String? ?? AppConfig.defaultHost;
    final port =
        int.tryParse(argResults?['port'] as String? ?? '') ??
        AppConfig.defaultPort;
    final daemon = argResults?['daemon'] as bool? ?? false;

    if (daemon) {
      final success = await ServerManager.startDaemon(host: host, port: port);
      return success ? ExitCode.success.code : ExitCode.tempFail.code;
    } else {
      await ServerManager.startForeground(host: host, port: port);
      return ExitCode.success.code;
    }
  }
}

class ServerStopCommand extends Command<int> {
  @override
  final String name = 'stop';

  @override
  final String description = 'Dừng terminal server đang chạy ngầm.';

  @override
  Future<int> run() async {
    final success = await ServerManager.stopServer();
    return success ? ExitCode.success.code : ExitCode.tempFail.code;
  }
}

class ServerStatusCommand extends Command<int> {
  @override
  final String name = 'status';

  @override
  final String description = 'Kiểm tra trạng thái máy chủ terminal.';

  ServerStatusCommand() {
    argParser
      ..addOption('host', abbr: 'H', help: 'Địa chỉ host cần kiểm tra')
      ..addOption('port', abbr: 'p', help: 'Cổng cần kiểm tra');
  }

  @override
  Future<int> run() async {
    final host = argResults?['host'] as String?;
    final portStr = argResults?['port'] as String?;
    final port = portStr != null ? int.tryParse(portStr) : null;

    final info = await ServerManager.checkStatus(host: host, port: port);
    if (info.isRunning) {
      stdout.writeln(
        TerminalStyle.success('● Server Antigravity đang HOẠT ĐỘNG!'),
      );
      stdout.writeln('  Địa chỉ:  ${info.host}:${info.port}');
      if (info.pid != null) {
        stdout.writeln('  PID:      ${info.pid}');
      }
      if (info.metadata != null) {
        final meta = info.metadata!;
        stdout.writeln('  Uptime:   ${meta['uptime_seconds']}s');
        stdout.writeln('  Online:   ${meta['active_users']} người');
        stdout.writeln('  Tổng tin: ${meta['total_messages']}');
      }
    } else {
      stdout.writeln(
        '${TerminalStyle.error('○ Server đang TẮT hoặc không phản hồi.')} (${info.host}:${info.port})',
      );
      stdout.writeln(
        TerminalStyle.mute(
          '  Gợi ý: Dùng `antigravity-chat server start` để bật server.',
        ),
      );
    }
    return ExitCode.success.code;
  }
}
