import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/chat_message.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

/// Service managing TCP Socket connection to the Antigravity Chat Server.
class ChatSocketService {
  Socket? _socket;
  StreamSubscription? _subscription;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  final _messageController = StreamController<MobileChatMessage>.broadcast();
  Stream<MobileChatMessage> get messageStream => _messageController.stream;

  final _usersController = StreamController<List<String>>.broadcast();
  Stream<List<String>> get usersStream => _usersController.stream;

  String host = '127.0.0.1';
  int port = 4040;
  String username = 'AndroidUser';
  String room = '#general';

  void _setStatus(ConnectionStatus s) {
    _status = s;
    _statusController.add(s);
  }

  Future<void> connect({
    required String targetHost,
    required int targetPort,
    required String targetUsername,
    required String targetRoom,
  }) async {
    host = targetHost;
    port = targetPort;
    username = targetUsername;
    room = targetRoom;

    _setStatus(ConnectionStatus.connecting);

    try {
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 4));
      _setStatus(ConnectionStatus.connected);

      // Listen to socket done
      _socket!.done.catchError((_) {});

      // Send join packet
      final joinPacket = {
        'type': 'join',
        'username': username,
        'room': room,
      };
      _socket!.write('${jsonEncode(joinPacket)}\n');

      // Request initial history & users
      _socket!.write('${jsonEncode({'type': 'history_req', 'limit': 30})}\n');
      _socket!.write('${jsonEncode({'type': 'users_req'})}\n');

      // Listen for incoming lines
      _subscription = _socket!
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleIncomingLine,
            onError: (err) {
              _setStatus(ConnectionStatus.error);
              disconnect();
            },
            onDone: () {
              _setStatus(ConnectionStatus.disconnected);
              disconnect();
            },
            cancelOnError: true,
          );
    } catch (e) {
      _setStatus(ConnectionStatus.error);
      rethrow;
    }
  }

  void _handleIncomingLine(String line) {
    if (line.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) return;

      final type = decoded['type'] as String? ?? '';
      switch (type) {
        case 'msg':
          final msg = MobileChatMessage.fromJson(decoded);
          _messageController.add(msg);
          break;
        case 'whisper':
          final msg = MobileChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: decoded['sender'] as String? ?? 'Anonymous',
            recipient: decoded['recipient'] as String?,
            text: decoded['text'] as String? ?? '',
            isWhisper: true,
          );
          _messageController.add(msg);
          break;
        case 'sys':
          final msg = MobileChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: 'System',
            text: decoded['text'] as String? ?? '',
            isSystem: true,
          );
          _messageController.add(msg);
          break;
        case 'err':
          final msg = MobileChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: 'System',
            text: 'Lỗi: ${decoded['text'] ?? ''}',
            isSystem: true,
          );
          _messageController.add(msg);
          break;
        case 'users_res':
          final rawUsers = decoded['users'] as List? ?? [];
          final users = rawUsers.map((e) => e.toString()).toList();
          _usersController.add(users);
          break;
        case 'history_res':
          final rawList = decoded['messages'] as List? ?? [];
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              _messageController.add(MobileChatMessage.fromJson(item));
            }
          }
          break;
      }
    } catch (_) {}
  }

  void sendMessage(String text) {
    if (_socket == null || _status != ConnectionStatus.connected) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (trimmed.startsWith('/')) {
      // Handle slash commands
      final parts = trimmed.split(RegExp(r'\s+'));
      final cmd = parts[0].toLowerCase();
      if (cmd == '/users' || cmd == '/who') {
        _socket!.write('${jsonEncode({'type': 'users_req'})}\n');
      } else if (cmd == '/history') {
        _socket!.write('${jsonEncode({'type': 'history_req', 'limit': 20})}\n');
      } else if (cmd == '/msg' && parts.length >= 3) {
        final target = parts[1];
        final whisperText = parts.sublist(2).join(' ');
        _socket!.write('${jsonEncode({
          'type': 'whisper',
          'sender': username,
          'recipient': target,
          'text': whisperText,
        })}\n');
      } else if (cmd == '/join' && parts.length > 1) {
        room = parts[1];
        _socket!.write('${jsonEncode({
          'type': 'join',
          'username': username,
          'room': room,
        })}\n');
      }
      return;
    }

    final packet = {
      'type': 'msg',
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender': username,
      'text': trimmed,
      'room': room,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _socket!.write('${jsonEncode(packet)}\n');
  }

  Future<void> disconnect() async {
    _subscription?.cancel();
    _subscription = null;
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
    _usersController.close();
  }
}
