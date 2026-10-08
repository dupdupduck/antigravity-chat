import 'package:args/command_runner.dart';

import 'server_command.dart';

/// Top-level shortcut command for checking server status.
class StatusCommand extends Command<int> {
  @override
  final String name = 'status';

  @override
  final String description =
      'Kiểm tra trạng thái máy chủ terminal (viết tắt của `server status`).';

  final ServerStatusCommand _delegate = ServerStatusCommand();

  StatusCommand() {
    argParser
      ..addOption('host', abbr: 'H', help: 'Địa chỉ host cần kiểm tra')
      ..addOption('port', abbr: 'p', help: 'Cổng cần kiểm tra');
  }

  @override
  Future<int> run() async {
    // Forward parsed args to delegate
    return await _delegate.run();
  }
}
