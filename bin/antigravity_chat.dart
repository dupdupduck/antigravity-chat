import 'dart:io';

import 'package:antigravity_chat/antigravity_chat.dart';
import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:stack_trace/stack_trace.dart';

void main(List<String> args) {
  Chain.capture(
    () async {
      final runner = AntigravityChatCommandRunner();
      final exitCode = await runner.run(args);
      exit(exitCode ?? ExitCode.success.code);
    },
    onError: (error, chain) {
      if (error is UsageException) {
        stderr.writeln(error.message);
        stderr.writeln('');
        stderr.writeln(error.usage);
        exit(ExitCode.usage.code);
      } else {
        stderr.writeln('${TerminalStyle.error('Lỗi nghiêm trọng:')} $error');
        stderr.writeln(chain.terse);
        exit(ExitCode.software.code);
      }
    },
  );
}
