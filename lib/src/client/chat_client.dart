import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/message.dart';
import '../models/protocol.dart';
import '../utils/ansi_styles.dart';
import '../utils/config.dart';
import 'terminal_ui.dart';

/// Client to interact with Antigravity Chat Server.
class ChatClient {
  final String host;
  final int port;
  Socket? _socket;
  StreamSubscription? _subscription;
  bool _isConnected = false;

  ChatClient({
    this.host = AppConfig.defaultHost,
    this.port = AppConfig.defaultPort,
  });

  bool get isConnected => _isConnected;

  /// Connects to the server.
  Future<void> connect() async {
    _socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 4),
    );
    _isConnected = true;
  }

  /// Sends a single message and closes connection (One-shot mode).
  Future<void> sendOneShot({
    required String username,
    required String text,
    String room = AppConfig.defaultRoom,
  }) async {
    await connect();
    // Join
    _socket!.write('${Packet.join(username: username, room: room).encode()}\n');
    await Future.delayed(const Duration(milliseconds: 50));

    // Send Msg
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: username,
      text: text,
      room: room,
    );
    _socket!.write('${Packet.msg(msg).encode()}\n');
    await _socket!.flush();
    await Future.delayed(const Duration(milliseconds: 100));
    await disconnect();
  }

  /// Requests the list of online users.
  Future<List<String>> fetchUsers() async {
    await connect();
    final completer = Completer<List<String>>();

    _socket!
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final packet = Packet.tryParse(line);
          if (packet != null && packet.type == PacketType.usersRes) {
            final rawUsers = packet.data['users'] as List? ?? [];
            final users = rawUsers.map((e) => e.toString()).toList();
            if (!completer.isCompleted) completer.complete(users);
          }
        });

    _socket!.write('${Packet.usersReq().encode()}\n');
    final result = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => <String>[],
    );
    await disconnect();
    return result;
  }

  /// Requests recent message history.
  Future<List<ChatMessage>> fetchHistory({int limit = 50}) async {
    await connect();
    final completer = Completer<List<ChatMessage>>();

    _socket!
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final packet = Packet.tryParse(line);
          if (packet != null && packet.type == PacketType.historyRes) {
            final rawList = packet.data['messages'] as List? ?? [];
            final messages = rawList
                .whereType<Map<String, dynamic>>()
                .map((e) => ChatMessage.fromJson(e))
                .toList();
            if (!completer.isCompleted) completer.complete(messages);
          }
        });

    _socket!.write('${Packet.historyReq(limit: limit).encode()}\n');
    final result = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => <ChatMessage>[],
    );
    await disconnect();
    return result;
  }

  /// Requests server status metadata.
  Future<Map<String, dynamic>?> fetchStatus() async {
    await connect();
    final completer = Completer<Map<String, dynamic>?>();

    _socket!
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final packet = Packet.tryParse(line);
          if (packet != null && packet.type == PacketType.statusRes) {
            if (!completer.isCompleted) completer.complete(packet.data);
          }
        });

    _socket!.write('${Packet.statusReq().encode()}\n');
    final result = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => null,
    );
    await disconnect();
    return result;
  }

  /// Starts an interactive chat session in terminal.
  Future<void> startInteractiveSession({
    required String username,
    String room = AppConfig.defaultRoom,
  }) async {
    await connect();

    TerminalUI.printBanner();
    stdout.writeln(TerminalStyle.success('Đã kết nối tới server $host:$port'));
    stdout.writeln(
      '${TerminalStyle.primary('Người dùng:')} $username | ${TerminalStyle.primary('Phòng:')} $room',
    );
    stdout.writeln(
      TerminalStyle.mute('Gõ /help để xem hướng dẫn, /quit để thoát.\n'),
    );

    // Join packet
    _socket!.write('${Packet.join(username: username, room: room).encode()}\n');

    var currentRoom = room;

    // Listen for incoming server messages
    _subscription = _socket!
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            final packet = Packet.tryParse(line);
            if (packet == null) return;

            switch (packet.type) {
              case PacketType.msg:
                final msg = ChatMessage.fromJson(packet.data);
                TerminalUI.printMessage(msg, currentUser: username);
                break;
              case PacketType.whisper:
                TerminalUI.printWhisperPacket(packet, currentUser: username);
                break;
              case PacketType.usersRes:
                final users = packet.data['users'] as List? ?? [];
                stdout.writeln(
                  '${TerminalStyle.highlight('👥 Người dùng đang online:')} ${users.join(', ')}',
                );
                break;
              case PacketType.historyRes:
                final rawList = packet.data['messages'] as List? ?? [];
                final messages = rawList
                    .whereType<Map<String, dynamic>>()
                    .map((e) => ChatMessage.fromJson(e))
                    .toList();
                stdout.writeln(TerminalStyle.highlight('📜 Lịch sử gần đây:'));
                for (final m in messages) {
                  TerminalUI.printMessage(m, currentUser: username);
                }
                break;
              case PacketType.sys:
                final text = packet.data['text'] as String? ?? '';
                stdout.writeln(TerminalStyle.warning('⚡ $text'));
                break;
              case PacketType.err:
                final text = packet.data['text'] as String? ?? '';
                stdout.writeln(TerminalStyle.error('❌ Lỗi: $text'));
                break;
              default:
                break;
            }
          },
          onError: (err) {
            stdout.writeln(
              '\n${TerminalStyle.error('Mất kết nối tới server:')} $err',
            );
            exit(0);
          },
          onDone: () {
            stdout.writeln(
              '\n${TerminalStyle.mute('Server đã đóng kết nối.')}',
            );
            exit(0);
          },
        );

    // Stdin loop
    final stdinSub = stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((
      line,
    ) {
      final input = line.trim();
      if (input.isEmpty) return;

      if (input.startsWith('/')) {
        // Slash commands
        final parts = input.split(RegExp(r'\s+'));
        final cmd = parts[0].toLowerCase();

        switch (cmd) {
          case '/help':
            TerminalUI.printHelp();
            break;
          case '/quit':
          case '/exit':
            stdout.writeln(TerminalStyle.mute('Đang ngắt kết nối...'));
            _socket?.write('${Packet.leave(username: username).encode()}\n');
            disconnect().then((_) => exit(0));
            return;
          case '/clear':
            TerminalUI.clearScreen();
            break;
          case '/who':
          case '/users':
            _socket?.write('${Packet.usersReq().encode()}\n');
            break;
          case '/history':
            int limit = 20;
            if (parts.length > 1) {
              limit = int.tryParse(parts[1]) ?? 20;
            }
            _socket?.write('${Packet.historyReq(limit: limit).encode()}\n');
            break;
          case '/join':
            if (parts.length > 1) {
              currentRoom = parts[1];
              _socket?.write(
                '${Packet.join(username: username, room: currentRoom).encode()}\n',
              );
              stdout.writeln(
                '${TerminalStyle.success('Đã chuyển sang phòng')} $currentRoom',
              );
            } else {
              stdout.writeln(
                TerminalStyle.warning('Cú pháp: /join <tên_phòng>'),
              );
            }
            break;
          case '/msg':
          case '/whisper':
            if (parts.length >= 3) {
              final target = parts[1];
              final whisperText = parts.sublist(2).join(' ');
              _socket?.write(
                '${Packet.whisper(sender: username, recipient: target, text: whisperText).encode()}\n',
              );
            } else {
              stdout.writeln(
                TerminalStyle.warning('Cú pháp: /msg <người_nhận> <nội_dung>'),
              );
            }
            break;
          default:
            stdout.writeln(
              TerminalStyle.warning(
                'Không hiểu lệnh $cmd. Gõ /help để xem trợ giúp.',
              ),
            );
        }
        return;
      }

      // Normal message
      final msg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: username,
        text: input,
        room: currentRoom,
      );
      _socket?.write('${Packet.msg(msg).encode()}\n');
    });

    final completer = Completer<void>();
    ProcessSignal.sigint.watch().listen((_) async {
      stdout.writeln('\n${TerminalStyle.mute('Đang thoát...')}');
      _socket?.write('${Packet.leave(username: username).encode()}\n');
      await stdinSub.cancel();
      await disconnect();
      exit(0);
    });

    await completer.future;
  }

  /// Disconnects socket.
  Future<void> disconnect() async {
    _isConnected = false;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }
}
