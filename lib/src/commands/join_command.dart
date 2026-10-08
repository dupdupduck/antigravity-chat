import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../client/chat_client.dart';
import '../utils/ansi_styles.dart';
import '../utils/config.dart';

/// Command to join an interactive chat session.
class JoinCommand extends Command<int> {
  @override
  final String name = 'join';

  @override
  final String description = 'Tham gia phiên chat trực tiếp trên terminal.';

  JoinCommand() {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Tên người dùng (mặc định: tên tài khoản hệ thống)',
      )
      ..addOption(
        'room',
        abbr: 'r',
        defaultsTo: AppConfig.defaultRoom,
        help: 'Phòng chat tham gia (mặc định: #general)',
      )
      ..addOption(
        'host',
        abbr: 'H',
        defaultsTo: AppConfig.defaultHost,
        help: 'Địa chỉ máy chủ (mặc định: 127.0.0.1)',
      )
      ..addOption(
        'port',
        abbr: 'p',
        defaultsTo: AppConfig.defaultPort.toString(),
        help: 'Cổng máy chủ (mặc định: 4040)',
      );
  }

  @override
  Future<int> run() async {
    final host = argResults?['host'] as String? ?? AppConfig.defaultHost;
    final port =
        int.tryParse(argResults?['port'] as String? ?? '') ??
        AppConfig.defaultPort;
    final room = argResults?['room'] as String? ?? AppConfig.defaultRoom;
    var name = argResults?['name'] as String?;

    if (name == null || name.trim().isEmpty) {
      name = AppConfig.getDefaultUsername();
    }

    final client = ChatClient(host: host, port: port);
    try {
      await client.startInteractiveSession(username: name, room: room);
      return ExitCode.success.code;
    } on SocketException catch (e) {
      stderr.writeln(
        '${TerminalStyle.error('Không thể kết nối đến máy chủ chat tại $host:$port:')} ${e.message}',
      );
      stderr.writeln(
        TerminalStyle.mute(
          'Hãy chắc chắn rằng bạn đã khởi động server bằng lệnh: `antigravity-chat server start`',
        ),
      );
      return ExitCode.unavailable.code;
    } catch (e) {
      stderr.writeln('${TerminalStyle.error('Lỗi khi tham gia chat:')} $e');
      return ExitCode.software.code;
    }
  }
}
