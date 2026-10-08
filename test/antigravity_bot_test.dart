import 'package:antigravity_chat/antigravity_chat.dart';
import 'package:test/test.dart';

void main() {
  group('AntigravityBot Tests', () {
    final bot = AntigravityBot();

    test('detects bot mentions correctly', () {
      expect(bot.isBotMention('@antigravity hello'), isTrue);
      expect(bot.isBotMention('@agy status'), isTrue);
      expect(bot.isBotMention('@bot quote'), isTrue);
      expect(bot.isBotMention('/ai how are you'), isTrue);
      expect(bot.isBotMention('just a normal message'), isFalse);
    });

    test('generates welcome message', () {
      final welcome = bot.welcomeMessage('Tester');
      expect(welcome, contains('Tester'));
      expect(welcome, contains('Antigravity'));
    });

    test('handles help query', () {
      final reply = bot.processQuery('@antigravity help');
      expect(reply, contains('@antigravity status'));
      expect(reply, contains('@antigravity time'));
    });

    test('handles status and sysinfo queries', () {
      final statusReply = bot.processQuery(
        '@antigravity status',
        connectedUsers: 3,
        uptime: const Duration(minutes: 15),
      );
      expect(statusReply, contains('Uptime: 0h 15m 0s'));
      expect(statusReply, contains('3'));

      final sysinfoReply = bot.processQuery('@antigravity sysinfo');
      expect(sysinfoReply, contains('Máy chủ'));
      expect(sysinfoReply, contains('CPU'));
    });

    test('handles time query', () {
      final timeReply = bot.processQuery('@antigravity time');
      expect(timeReply, contains('Thời gian hiện tại:'));
    });

    test('handles roll command', () {
      final rollReply = bot.processQuery('@antigravity roll 20');
      expect(rollReply, contains('🎲'));
      expect(rollReply, contains('từ 1 đến 20'));
    });
  });
}
