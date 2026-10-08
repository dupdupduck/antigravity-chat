import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../client/chat_client.dart';
import '../client/terminal_ui.dart';
import '../utils/ansi_styles.dart';
import '../utils/config.dart';

/// Command to view chat message history.
class HistoryCommand extends Command<int> {
  @override
  final String name = 'history';

  @override
  final String description = 'Xem lại lịch sử tin nhắn gần đây trên máy chủ.';

  HistoryCommand() {
    argParser
      ..addOption(
        'limit',
        abbr: 'l',
        defaultsTo: '20',
        help: 'Số lượng tin nhắn cần xem',
      )
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
    final limit = int.tryParse(argResults?['limit'] as String? ?? '20') ?? 20;

    final client = ChatClient(host: host, port: port);
    try {
      final messages = await client.fetchHistory(limit: limit);
      if (messages.isEmpty) {
        stdout.writeln(
          TerminalStyle.mute('Chưa có tin nhắn nào trong lịch sử.'),
        );
      } else {
        stdout.writeln(
          TerminalStyle.highlight('📜 Lịch sử $limit tin nhắn gần nhất:'),
        );
        for (final m in messages) {
          TerminalUI.printMessage(m);
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
        '${TerminalStyle.error('Lỗi khi lấy lịch sử tin nhắn:')} $e',
      );
      return ExitCode.software.code;
    }
  }
}
