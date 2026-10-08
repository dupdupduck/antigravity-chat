import 'dart:convert';

/// Represents a chat message in the Antigravity mobile app.
class MobileChatMessage {
  final String id;
  final String sender;
  final String text;
  final String room;
  final DateTime timestamp;
  final bool isSystem;
  final bool isWhisper;
  final String? recipient;

  MobileChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.room = '#general',
    DateTime? timestamp,
    this.isSystem = false,
    this.isWhisper = false,
    this.recipient,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isBot => sender.contains('Antigravity');

  factory MobileChatMessage.fromJson(Map<String, dynamic> json) {
    return MobileChatMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sender: json['sender'] as String? ?? 'Anonymous',
      text: json['text'] as String? ?? '',
      room: json['room'] as String? ?? '#general',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isSystem: json['is_system'] as bool? ?? false,
      isWhisper: json['is_whisper'] as bool? ?? false,
      recipient: json['recipient'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'text': text,
    'room': room,
    'timestamp': timestamp.toIso8601String(),
    'is_system': isSystem,
    'is_whisper': isWhisper,
    if (recipient != null) 'recipient': recipient,
  };
}
