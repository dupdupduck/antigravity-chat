import 'dart:io';

import '../models/protocol.dart';

/// Represents an active client connection on the chat server.
class ClientSession {
  final Socket socket;
  String username;
  String room;
  final DateTime connectedAt;

  bool _isClosed = false;

  ClientSession({
    required this.socket,
    this.username = 'Anonymous',
    this.room = '#general',
  }) : connectedAt = DateTime.now() {
    socket.done.catchError((_) {});
  }

  String get remoteAddress {
    try {
      return '${socket.remoteAddress.address}:${socket.remotePort}';
    } catch (_) {
      return 'unknown';
    }
  }

  void sendPacket(Packet packet) {
    if (_isClosed) return;
    try {
      final data = '${packet.encode()}\n';
      socket.write(data);
    } catch (_) {
      _isClosed = true;
    }
  }

  void close() {
    _isClosed = true;
    try {
      socket.destroy();
    } catch (_) {}
  }
}
