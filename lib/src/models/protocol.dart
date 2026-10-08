import 'dart:convert';

import 'message.dart';

/// Network packet types for Antigravity Chat.
enum PacketType {
  join,
  leave,
  msg,
  whisper,
  historyReq,
  historyRes,
  usersReq,
  usersRes,
  statusReq,
  statusRes,
  sys,
  err,
  unknown;

  static PacketType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'join':
        return PacketType.join;
      case 'leave':
        return PacketType.leave;
      case 'msg':
        return PacketType.msg;
      case 'whisper':
        return PacketType.whisper;
      case 'history_req':
        return PacketType.historyReq;
      case 'history_res':
        return PacketType.historyRes;
      case 'users_req':
        return PacketType.usersReq;
      case 'users_res':
        return PacketType.usersRes;
      case 'status_req':
        return PacketType.statusReq;
      case 'status_res':
        return PacketType.statusRes;
      case 'sys':
        return PacketType.sys;
      case 'err':
        return PacketType.err;
      default:
        return PacketType.unknown;
    }
  }

  String toWireString() {
    switch (this) {
      case PacketType.join:
        return 'join';
      case PacketType.leave:
        return 'leave';
      case PacketType.msg:
        return 'msg';
      case PacketType.whisper:
        return 'whisper';
      case PacketType.historyReq:
        return 'history_req';
      case PacketType.historyRes:
        return 'history_res';
      case PacketType.usersReq:
        return 'users_req';
      case PacketType.usersRes:
        return 'users_res';
      case PacketType.statusReq:
        return 'status_req';
      case PacketType.statusRes:
        return 'status_res';
      case PacketType.sys:
        return 'sys';
      case PacketType.err:
        return 'err';
      case PacketType.unknown:
        return 'unknown';
    }
  }
}

/// Represents an Antigravity Chat wire packet.
class Packet {
  final PacketType type;
  final Map<String, dynamic> data;

  Packet({required this.type, required this.data});

  factory Packet.join({required String username, String room = '#general'}) {
    return Packet(
      type: PacketType.join,
      data: {'username': username, 'room': room},
    );
  }

  factory Packet.leave({required String username}) {
    return Packet(type: PacketType.leave, data: {'username': username});
  }

  factory Packet.msg(ChatMessage message) {
    return Packet(type: PacketType.msg, data: message.toJson());
  }

  factory Packet.whisper({
    required String sender,
    required String recipient,
    required String text,
  }) {
    return Packet(
      type: PacketType.whisper,
      data: {
        'sender': sender,
        'recipient': recipient,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  factory Packet.historyReq({int limit = 50}) {
    return Packet(type: PacketType.historyReq, data: {'limit': limit});
  }

  factory Packet.historyRes(List<ChatMessage> messages) {
    return Packet(
      type: PacketType.historyRes,
      data: {'messages': messages.map((m) => m.toJson()).toList()},
    );
  }

  factory Packet.usersReq() {
    return Packet(type: PacketType.usersReq, data: {});
  }

  factory Packet.usersRes(List<String> users) {
    return Packet(type: PacketType.usersRes, data: {'users': users});
  }

  factory Packet.statusReq() {
    return Packet(type: PacketType.statusReq, data: {});
  }

  factory Packet.statusRes({
    required String serverName,
    required int uptimeSeconds,
    required int activeUsers,
    required int totalMessages,
    required String host,
    required int port,
  }) {
    return Packet(
      type: PacketType.statusRes,
      data: {
        'server_name': serverName,
        'uptime_seconds': uptimeSeconds,
        'active_users': activeUsers,
        'total_messages': totalMessages,
        'host': host,
        'port': port,
      },
    );
  }

  factory Packet.sys(String text) {
    return Packet(type: PacketType.sys, data: {'text': text});
  }

  factory Packet.err(String text) {
    return Packet(type: PacketType.err, data: {'text': text});
  }

  String encode() {
    final map = {'type': type.toWireString(), ...data};
    return jsonEncode(map);
  }

  static Packet? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final typeStr = decoded['type'] as String? ?? '';
      final type = PacketType.fromString(typeStr);
      final data = Map<String, dynamic>.from(decoded)..remove('type');
      return Packet(type: type, data: data);
    } catch (_) {
      return null;
    }
  }
}
