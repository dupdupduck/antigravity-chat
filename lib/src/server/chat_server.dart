import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/message.dart';
import '../models/protocol.dart';
import '../utils/ansi_styles.dart';
import '../utils/config.dart';
import 'antigravity_bot.dart';
import 'client_session.dart';

/// The core Terminal Chat Server for Antigravity.
class ChatServer {
  final String host;
  final int port;
  final AntigravityBot bot = AntigravityBot();

  ServerSocket? _serverSocket;
  final List<ClientSession> _clients = [];
  final List<ChatMessage> _history = [];
  final DateTime _startedAt = DateTime.now();
  int _totalMessagesCounter = 0;
  bool _isRunning = false;

  ChatServer({
    this.host = AppConfig.defaultHost,
    this.port = AppConfig.defaultPort,
  });

  bool get isRunning => _isRunning;
  DateTime get startedAt => _startedAt;
  Duration get uptime => DateTime.now().difference(_startedAt);
  int get clientCount => _clients.length;

  /// Starts the socket server.
  Future<void> start() async {
    _loadHistory();
    _serverSocket = await ServerSocket.bind(host, port, shared: true);
    _isRunning = true;

    final banner =
        '''
${TerminalStyle.banner()}
${TerminalStyle.success('🚀 Antigravity Chat Server is RUNNING!')}
${TerminalStyle.primary('  Host: ')}$host
${TerminalStyle.primary('  Port: ')}$port
${TerminalStyle.primary('  PID:  ')}$pid
${TerminalStyle.mute('  Started: ')}${_startedAt.toLocal()}
''';
    stdout.writeln(banner);

    _serverSocket!.listen(
      _handleNewConnection,
      onError: (error) {
        stderr.writeln('${TerminalStyle.error('[Server Error]')} $error');
      },
      onDone: () {
        _isRunning = false;
      },
      cancelOnError: false,
    );
  }

  void _handleNewConnection(Socket socket) {
    socket.done.catchError((_) {});
    final session = ClientSession(socket: socket);
    _clients.add(session);

    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) => _processClientLine(session, line),
          onError: (error) {
            _removeClient(session);
          },
          onDone: () {
            _removeClient(session);
          },
          cancelOnError: true,
        );
  }

  void _processClientLine(ClientSession session, String line) {
    if (line.trim().isEmpty) return;
    final packet = Packet.tryParse(line);
    if (packet == null) return;

    switch (packet.type) {
      case PacketType.join:
        _handleJoin(session, packet);
        break;
      case PacketType.msg:
        _handleMsg(session, packet);
        break;
      case PacketType.whisper:
        _handleWhisper(session, packet);
        break;
      case PacketType.leave:
        _removeClient(session);
        break;
      case PacketType.historyReq:
        _handleHistoryReq(session, packet);
        break;
      case PacketType.usersReq:
        _handleUsersReq(session);
        break;
      case PacketType.statusReq:
        _handleStatusReq(session);
        break;
      default:
        break;
    }
  }

  void _handleJoin(ClientSession session, Packet packet) {
    final username = (packet.data['username'] as String? ?? 'Anonymous').trim();
    final room = (packet.data['room'] as String? ?? AppConfig.defaultRoom)
        .trim();

    session.username = username.isNotEmpty
        ? username
        : 'User_${_clients.indexOf(session) + 1}';
    session.room = room.isNotEmpty ? room : AppConfig.defaultRoom;

    stdout.writeln(
      '${TerminalStyle.mute('[JOIN]')} ${session.username} connected from ${session.remoteAddress} (Room: ${session.room})',
    );

    // Notify room of new user
    final joinMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'System',
      text: '${session.username} đã tham gia phòng ${session.room}.',
      room: session.room,
      isSystem: true,
    );
    _recordMessage(joinMsg);
    _broadcast(joinMsg, targetRoom: session.room);

    // Bot sends welcome message
    Timer(const Duration(milliseconds: 300), () {
      if (!_clients.contains(session)) return;
      final welcome = bot.welcomeMessage(session.username);
      final botMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: AntigravityBot.botName,
        text: welcome,
        room: session.room,
      );
      _recordMessage(botMsg);
      _broadcast(botMsg, targetRoom: session.room);
    });
  }

  void _handleMsg(ClientSession session, Packet packet) {
    final rawText = (packet.data['text'] as String? ?? '').trim();
    if (rawText.isEmpty) return;

    final room = packet.data['room'] as String? ?? session.room;
    final sender = session.username;

    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: sender,
      text: rawText,
      room: room,
    );

    _recordMessage(msg);
    _broadcast(msg, targetRoom: room);

    stdout.writeln('${TerminalStyle.mute('[MSG $room]')} <$sender> $rawText');

    // Check if message mentions Antigravity Bot
    if (bot.isBotMention(rawText)) {
      Timer(const Duration(milliseconds: 200), () {
        final reply = bot.processQuery(
          rawText,
          connectedUsers: _clients.length,
          uptime: uptime,
        );
        final botMsg = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: AntigravityBot.botName,
          text: reply,
          room: room,
        );
        _recordMessage(botMsg);
        _broadcast(botMsg, targetRoom: room);
      });
    }
  }

  void _handleWhisper(ClientSession session, Packet packet) {
    final recipientName = (packet.data['recipient'] as String? ?? '').trim();
    final text = (packet.data['text'] as String? ?? '').trim();
    if (recipientName.isEmpty || text.isEmpty) return;

    final target = _clients.cast<ClientSession?>().firstWhere(
      (c) => c?.username.toLowerCase() == recipientName.toLowerCase(),
      orElse: () => null,
    );

    if (target != null) {
      final whisperPacket = Packet.whisper(
        sender: session.username,
        recipient: recipientName,
        text: text,
      );
      target.sendPacket(whisperPacket);
      session.sendPacket(whisperPacket);
    } else {
      session.sendPacket(
        Packet.err('Không tìm thấy người dùng "$recipientName" đang online.'),
      );
    }
  }

  void _handleHistoryReq(ClientSession session, Packet packet) {
    final limit = packet.data['limit'] as int? ?? 50;
    final messages = _history.reversed.take(limit).toList().reversed.toList();
    session.sendPacket(Packet.historyRes(messages));
  }

  void _handleUsersReq(ClientSession session) {
    final users = _clients.map((c) => c.username).toSet().toList();
    session.sendPacket(Packet.usersRes(users));
  }

  void _handleStatusReq(ClientSession session) {
    session.sendPacket(
      Packet.statusRes(
        serverName: 'Antigravity Chat Core',
        uptimeSeconds: uptime.inSeconds,
        activeUsers: _clients.length,
        totalMessages: _totalMessagesCounter,
        host: host,
        port: port,
      ),
    );
  }

  void _removeClient(ClientSession session) {
    if (!_clients.contains(session)) return;
    _clients.remove(session);
    stdout.writeln(
      '${TerminalStyle.mute('[LEAVE]')} ${session.username} disconnected.',
    );

    final leaveMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'System',
      text: '${session.username} đã rời phòng.',
      room: session.room,
      isSystem: true,
    );
    _recordMessage(leaveMsg);
    _broadcast(leaveMsg, targetRoom: session.room);
    session.close();
  }

  void _recordMessage(ChatMessage msg) {
    _totalMessagesCounter++;
    _history.add(msg);
    if (_history.length > 200) {
      _history.removeAt(0);
    }
    _persistMessage(msg);
  }

  void _broadcast(ChatMessage message, {String? targetRoom}) {
    final packet = Packet.msg(message);
    for (final client in List<ClientSession>.from(_clients)) {
      if (targetRoom == null || client.room == targetRoom) {
        try {
          client.sendPacket(packet);
        } catch (_) {}
      }
    }
  }

  void _loadHistory() {
    try {
      final file = AppConfig.historyFile;
      if (file.existsSync()) {
        final lines = file.readAsLinesSync();
        for (final line in lines.reversed.take(100).toList().reversed) {
          if (line.trim().isEmpty) continue;
          final json = jsonDecode(line) as Map<String, dynamic>;
          _history.add(ChatMessage.fromJson(json));
        }
      }
    } catch (_) {}
  }

  void _persistMessage(ChatMessage msg) {
    try {
      final file = AppConfig.historyFile;
      file.writeAsStringSync(
        '${jsonEncode(msg.toJson())}\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  /// Stops the server gracefully.
  Future<void> stop() async {
    _isRunning = false;
    for (final client in List<ClientSession>.from(_clients)) {
      client.sendPacket(Packet.sys('Server đang tắt...'));
      client.close();
    }
    _clients.clear();
    await _serverSocket?.close();
    _serverSocket = null;
  }
}
