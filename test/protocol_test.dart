import 'package:antigravity_chat/antigravity_chat.dart';
import 'package:test/test.dart';

void main() {
  group('ChatMessage Tests', () {
    test('creates ChatMessage with defaults and serializes to JSON', () {
      final msg = ChatMessage(
        id: 'msg_1',
        sender: 'Alice',
        text: 'Hello world',
        room: '#general',
      );

      expect(msg.id, equals('msg_1'));
      expect(msg.sender, equals('Alice'));
      expect(msg.text, equals('Hello world'));
      expect(msg.room, equals('#general'));
      expect(msg.isSystem, isFalse);

      final json = msg.toJson();
      expect(json['id'], equals('msg_1'));
      expect(json['sender'], equals('Alice'));
      expect(json['text'], equals('Hello world'));

      final restored = ChatMessage.fromJson(json);
      expect(restored.id, equals(msg.id));
      expect(restored.sender, equals(msg.sender));
      expect(restored.text, equals(msg.text));
    });

    test('formats toString correctly for whisper and system message', () {
      final whisper = ChatMessage(
        id: 'w1',
        sender: 'Bob',
        recipient: 'Alice',
        text: 'Secret note',
        isWhisper: true,
      );
      expect(whisper.toString(), contains('(whisper from Bob): Secret note'));

      final sys = ChatMessage(
        id: 's1',
        sender: 'System',
        text: 'Bob connected',
        isSystem: true,
      );
      expect(sys.toString(), contains('* Bob connected *'));
    });
  });

  group('Packet Protocol Tests', () {
    test('encodes and decodes join packet', () {
      final packet = Packet.join(username: 'Charlie', room: '#dev');
      final encoded = packet.encode();
      final parsed = Packet.tryParse(encoded);

      expect(parsed, isNotNull);
      expect(parsed!.type, equals(PacketType.join));
      expect(parsed.data['username'], equals('Charlie'));
      expect(parsed.data['room'], equals('#dev'));
    });

    test('encodes and decodes whisper packet', () {
      final packet = Packet.whisper(
        sender: 'Alice',
        recipient: 'Bob',
        text: 'Hi Bob',
      );
      final encoded = packet.encode();
      final parsed = Packet.tryParse(encoded);

      expect(parsed, isNotNull);
      expect(parsed!.type, equals(PacketType.whisper));
      expect(parsed.data['sender'], equals('Alice'));
      expect(parsed.data['recipient'], equals('Bob'));
      expect(parsed.data['text'], equals('Hi Bob'));
    });

    test('encodes and decodes statusRes packet', () {
      final packet = Packet.statusRes(
        serverName: 'Antigravity Core',
        uptimeSeconds: 120,
        activeUsers: 5,
        totalMessages: 42,
        host: '127.0.0.1',
        port: 4040,
      );
      final encoded = packet.encode();
      final parsed = Packet.tryParse(encoded);

      expect(parsed, isNotNull);
      expect(parsed!.type, equals(PacketType.statusRes));
      expect(parsed.data['active_users'], equals(5));
      expect(parsed.data['total_messages'], equals(42));
    });
  });
}
