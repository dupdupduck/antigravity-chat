import 'package:antigravity_chat/antigravity_chat.dart';
import 'package:args/command_runner.dart';
import 'package:test/test.dart';

void main() {
  group('AntigravityChatCommandRunner Tests', () {
    late AntigravityChatCommandRunner runner;

    setUp(() {
      runner = AntigravityChatCommandRunner();
    });

    test('registers all required subcommands', () {
      expect(runner.commands.containsKey('server'), isTrue);
      expect(runner.commands.containsKey('join'), isTrue);
      expect(runner.commands.containsKey('send'), isTrue);
      expect(runner.commands.containsKey('users'), isTrue);
      expect(runner.commands.containsKey('history'), isTrue);
      expect(runner.commands.containsKey('status'), isTrue);
    });

    test('handles --version flag gracefully', () async {
      final code = await runner.run(['--version']);
      expect(code, equals(0));
    });

    test('throws UsageException on unknown command', () async {
      expect(() => runner.run(['unknown_cmd']), throwsA(isA<UsageException>()));
    });

    test('server command contains subcommands start, stop, status', () {
      final serverCmd = runner.commands['server'];
      expect(serverCmd, isNotNull);
      expect(serverCmd!.subcommands.containsKey('start'), isTrue);
      expect(serverCmd.subcommands.containsKey('stop'), isTrue);
      expect(serverCmd.subcommands.containsKey('status'), isTrue);
    });
  });
}
