import 'dart:io';

import '../models/message.dart';
import '../models/protocol.dart';
import '../utils/ansi_styles.dart';

/// Terminal UI renderer for Antigravity Chat.
class TerminalUI {
  static void printBanner() {
    stdout.writeln(TerminalStyle.banner());
  }

  static void printHelp() {
    stdout.writeln('''
${TerminalStyle.highlight('=== CÁC LỆNH TRONG TERMINAL CHAT ===')}
  ${TerminalStyle.primary('/help')}                 - Hiển thị bảng trợ giúp này
  ${TerminalStyle.primary('/users')} hoặc ${TerminalStyle.primary('/who')}     - Xem danh sách người đang online
  ${TerminalStyle.primary('/msg <user> <text>')}    - Gửi tin nhắn riêng (whisper) cho người khác
  ${TerminalStyle.primary('/join <phong>')}         - Đổi sang phòng chat khác (ví dụ: /join #dev)
  ${TerminalStyle.primary('/history [so_luong]')}   - Xem lại lịch sử tin nhắn gần đây
  ${TerminalStyle.primary('/clear')}                - Xóa sạch màn hình terminal
  ${TerminalStyle.primary('/quit')} hoặc ${TerminalStyle.primary('/exit')}     - Rời khỏi phòng chat

${TerminalStyle.highlight('=== TRỢ LÝ AI ANTIGRAVITY ===')}
  Gõ ${TerminalStyle.bot('@antigravity help')} trong tin nhắn để gọi trợ lý AI Antigravity!
''');
  }

  static void printMessage(ChatMessage msg, {String? currentUser}) {
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}:${msg.timestamp.second.toString().padLeft(2, '0')}';
    final timeFormatted = TerminalStyle.mute('[$timeStr]');

    if (msg.isSystem) {
      stdout.writeln(
        '$timeFormatted ${TerminalStyle.warning('⚡ ${msg.text}')}',
      );
      return;
    }

    if (msg.isWhisper) {
      final isFromMe = msg.sender == currentUser;
      final whisperLabel = isFromMe
          ? '${TerminalStyle.magenta}(Thầm thì tới ${msg.recipient}):${TerminalStyle.reset}'
          : '${TerminalStyle.magenta}(Thầm thì từ ${msg.sender}):${TerminalStyle.reset}';
      stdout.writeln(
        '$timeFormatted $whisperLabel ${TerminalStyle.italic}${msg.text}${TerminalStyle.reset}',
      );
      return;
    }

    if (msg.sender == '🤖 Antigravity') {
      stdout.writeln(
        '$timeFormatted ${TerminalStyle.bot('🤖 Antigravity')} ${TerminalStyle.cyan}${msg.text}${TerminalStyle.reset}',
      );
      return;
    }

    final isMe = msg.sender == currentUser;
    final senderDisplay = isMe
        ? '${TerminalStyle.brightGreen}${TerminalStyle.bold}[Bạn]${TerminalStyle.reset}'
        : TerminalStyle.userColor(msg.sender);

    stdout.writeln('$timeFormatted $senderDisplay: ${msg.text}');
  }

  static void printWhisperPacket(Packet packet, {String? currentUser}) {
    final sender = packet.data['sender'] as String? ?? 'Anonymous';
    final recipient = packet.data['recipient'] as String? ?? '';
    final text = packet.data['text'] as String? ?? '';
    final isMe = sender == currentUser;

    final label = isMe
        ? '${TerminalStyle.magenta}(Thầm thì tới $recipient):${TerminalStyle.reset}'
        : '${TerminalStyle.magenta}(Thầm thì từ $sender):${TerminalStyle.reset}';
    stdout.writeln('$label ${TerminalStyle.italic}$text${TerminalStyle.reset}');
  }

  static void clearScreen() {
    stdout.write('\x1B[2J\x1B[0;0H');
  }
}
