import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import 'commands/history_command.dart';
import 'commands/join_command.dart';
import 'commands/send_command.dart';
import 'commands/server_command.dart';
import 'commands/status_command.dart';
import 'commands/users_command.dart';
import 'utils/ansi_styles.dart';
import 'utils/config.dart';

/// Custom CommandRunner for Antigravity Chat.
class AntigravityChatCommandRunner extends CommandRunner<int> {
  AntigravityChatCommandRunner()
    : super(
        AppConfig.appName,
        'Ứng dụng nhắn tin Antigravity đa năng trên Terminal với máy chủ riêng biệt và trợ lý AI tích hợp.',
      ) {
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Hiển thị phiên bản ứng dụng.',
      )
      ..addFlag(
        'verbose',
        negatable: false,
        help: 'Hiển thị log chi tiết khi thực thi.',
      );

    addCommand(ServerCommand());
    addCommand(JoinCommand());
    addCommand(SendCommand());
    addCommand(UsersCommand());
    addCommand(HistoryCommand());
    addCommand(StatusCommand());
  }

  @override
  String get usageFooter =>
      '''
Ví dụ sử dụng phổ biến:
  ${AppConfig.appName} server start --daemon      Khởi động server ngầm
  ${AppConfig.appName} join --name Alice          Tham gia chat trực tiếp
  ${AppConfig.appName} send -m "Xin chào!"        Gửi tin nhắn nhanh từ lệnh terminal
  echo "Xong việc!" | ${AppConfig.appName} send   Pipe nội dung từ lệnh khác vào chat
  ${AppConfig.appName} users                      Xem ai đang online
  ${AppConfig.appName} history --limit 10         Xem 10 tin nhắn gần nhất
  ${AppConfig.appName} status                     Kiểm tra máy chủ

Để gọi lệnh từ bất kỳ đâu, binary được cài đặt vào PATH tại:
  /data/data/com.termux/files/usr/bin/antigravity-chat (hoặc alias: agchat)
''';

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] as bool? ?? false) {
      stdout.writeln('${AppConfig.appName} phiên bản ${AppConfig.appVersion}');
      return ExitCode.success.code;
    }

    if (topLevelResults.command == null) {
      if (topLevelResults.rest.isNotEmpty) {
        throw UsageException(
          'Could not find a command named "${topLevelResults.rest.first}".',
          usage,
        );
      }
      // If no command is provided, print banner and help
      stdout.writeln(TerminalStyle.banner());
      printUsage();
      return ExitCode.success.code;
    }

    final code = await super.runCommand(topLevelResults);
    return code ?? ExitCode.success.code;
  }
}
