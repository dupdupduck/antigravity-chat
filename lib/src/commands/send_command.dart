import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../client/chat_client.dart';
import '../utils/ansi_styles.dart';
import '../utils/config.dart';

/// Command to send a one-shot message from terminal or standard input.
class SendCommand extends Command<int> {
  @override
  final String name = 'send';

  @override
  final String description =
      'Gửi tin nhắn nhanh vào phòng chat từ terminal (hỗ trợ pipe stdin).';

  SendCommand() {
    argParser
      ..addOption('message', abbr: 'm', help: 'Nội dung tin nhắn cần gửi')
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Tên người gửi (mặc định: tên tài khoản hệ thống)',
      )
      ..addOption(
        'room',
        abbr: 'r',
        defaultsTo: AppConfig.defaultRoom,
        help: 'Phòng chat (mặc định: #general)',
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
    final room = argResults?['room'] as String? ?? AppConfig.defaultRoom;
    var name = argResults?['name'] as String?;
    var message = argResults?['message'] as String?;

    if (name == null || name.trim().isEmpty) {
      name = AppConfig.getDefaultUsername();
    }

    // Check if piped from stdin if message flag is not provided
    if (message == null || message.trim().isEmpty) {
      if (!stdin.hasTerminal) {
        final lines = await stdin
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .toList();
        message = lines.join('\n').trim();
      }
    }

    if (message == null || message.trim().isEmpty) {
      stderr.writeln(
        '${TerminalStyle.error('Lỗi:')} Vui lòng cung cấp tin nhắn bằng cờ `-m "nội dung"` hoặc pipe qua stdin.',
      );
      return ExitCode.usage.code;
    }

    final client = ChatClient(host: host, port: port);
    try {
      await client.sendOneShot(username: name, text: message, room: room);
      stdout.writeln(
        '${TerminalStyle.success('✔')} Đã gửi tin nhắn tới [$room] dưới tên [$name]',
      );
      return ExitCode.success.code;
    } on SocketException catch (e) {
      stderr.writeln(
        '${TerminalStyle.error('Không thể kết nối đến máy chủ chat tại $host:$port:')} ${e.message}',
      );
      return ExitCode.unavailable.code;
    } catch (e) {
      stderr.writeln('${TerminalStyle.error('Lỗi khi gửi tin nhắn:')} $e');
      return ExitCode.software.code;
    }
  }
}
