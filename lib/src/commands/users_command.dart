import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../client/chat_client.dart';
import '../utils/ansi_styles.dart';
import '../utils/config.dart';

/// Command to list currently online users.
class UsersCommand extends Command<int> {
  @override
  final String name = 'users';

  @override
  List<String> get aliases => ['who', 'online'];

  @override
  final String description =
      'Xem danh sách người dùng đang kết nối trực tuyến.';

  UsersCommand() {
    argParser
      ..addOption(
        'host',
        abbr: 'H',
        defaultsTo: AppConfig.defaultHost,
        help: 'Địa chỉ máy chủ',
      )
      ..addOption(
        'port',
        abbr: 'p',
        defaultsTo: AppConfig.defaultPort.toString(),
        help: 'Cổng máy chủ',
      );
  }

  @override
  Future<int> run() async {
    final host = argResults?['host'] as String? ?? AppConfig.defaultHost;
    final port =
        int.tryParse(argResults?['port'] as String? ?? '') ??
        AppConfig.defaultPort;

    final client = ChatClient(host: host, port: port);
    try {
      final users = await client.fetchUsers();
      if (users.isEmpty) {
        stdout.writeln(
          TerminalStyle.mute('Hiện không có người dùng nào đang kết nối.'),
        );
      } else {
        stdout.writeln(
          TerminalStyle.highlight('👥 Người dùng online (${users.length}):'),
        );
        for (final u in users) {
          stdout.writeln('  • ${TerminalStyle.userColor(u)}');
        }
      }
      return ExitCode.success.code;
    } on SocketException catch (e) {
      stderr.writeln(
        '${TerminalStyle.error('Không thể kết nối đến máy chủ chat tại $host:$port:')} ${e.message}',
      );
      return ExitCode.unavailable.code;
    } catch (e) {
      stderr.writeln(
        '${TerminalStyle.error('Lỗi khi lấy danh sách người dùng:')} $e',
      );
      return ExitCode.software.code;
    }
  }
}
