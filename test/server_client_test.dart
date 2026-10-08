import 'package:antigravity_chat/antigravity_chat.dart';
import 'package:test/test.dart';

void main() {
  group('Server & Client Integration Tests', () {
    late ChatServer server;
    const testPort = 4099;
    const testHost = '127.0.0.1';

    setUp(() async {
      server = ChatServer(host: testHost, port: testPort);
      await server.start();
    });

    tearDown(() async {
      await server.stop();
    });

    test('server starts, reports running, and stops', () {
      expect(server.isRunning, isTrue);
      expect(server.uptime.inSeconds, greaterThanOrEqualTo(0));
    });

    test('client connects, fetches status, and queries users', () async {
      final client = ChatClient(host: testHost, port: testPort);
      final status = await client.fetchStatus();

      expect(status, isNotNull);
      expect(status!['server_name'], equals('Antigravity Chat Core'));
      expect(status['port'], equals(testPort));
    });

    test('client sends one-shot message and records in history', () async {
      final clientSender = ChatClient(host: testHost, port: testPort);
      await clientSender.sendOneShot(
        username: 'TestBot',
        text: 'Integration test message 123',
        room: '#test',
      );

      // Verify history
      final clientReader = ChatClient(host: testHost, port: testPort);
      final history = await clientReader.fetchHistory(limit: 10);

      final found = history.any(
        (m) =>
            m.sender == 'TestBot' && m.text == 'Integration test message 123',
      );
      expect(found, isTrue);
    });
  });
}
