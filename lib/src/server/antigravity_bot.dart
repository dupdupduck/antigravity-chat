import 'dart:io';
import 'dart:math';

/// Intelligent Antigravity Bot residing inside the Terminal Server.
class AntigravityBot {
  static const String botName = '🤖 Antigravity';

  final List<String> _quotes = [
    '“Any sufficiently advanced technology is indistinguishable from magic.” - Arthur C. Clarke',
    '“Talk is cheap. Show me the code.” - Linus Torvalds',
    '“Simplicity is prerequisite for reliability.” - Edsger W. Dijkstra',
    '“Antigravity: Elevating terminal communication to the next orbit!”',
    '“Computers are fast; developers are patient.”',
  ];

  final List<String> _jokes = [
    'Why do programmers prefer dark mode? Because light attracts bugs!',
    'There are 10 types of people in the world: those who understand binary, and those who do not.',
    'A SQL query walks into a bar, walks up to two tables and asks: "Can I join you?"',
    '!false - It\'s funny because it\'s true.',
    'Why did the developer go broke? Because he used up all his cache.',
  ];

  /// Checks if a message text is addressed to Antigravity Bot.
  bool isBotMention(String text) {
    final lower = text.trim().toLowerCase();
    return lower.startsWith('@antigravity') ||
        lower.startsWith('@agy') ||
        lower.startsWith('@bot') ||
        lower.startsWith('/ai');
  }

  /// Generates a welcome message for a newly joined user.
  String welcomeMessage(String username) {
    return 'Xin chào $username! Tôi là $botName. Nhập `@antigravity help` để xem các lệnh trợ giúp!';
  }

  /// Processes a prompt directed to the bot.
  String processQuery(
    String prompt, {
    int connectedUsers = 1,
    Duration? uptime,
  }) {
    // Strip trigger prefix
    var query = prompt.trim();
    if (query.toLowerCase().startsWith('@antigravity')) {
      query = query.substring('@antigravity'.length).trim();
    } else if (query.toLowerCase().startsWith('@agy')) {
      query = query.substring('@agy'.length).trim();
    } else if (query.toLowerCase().startsWith('@bot')) {
      query = query.substring('@bot'.length).trim();
    } else if (query.toLowerCase().startsWith('/ai')) {
      query = query.substring('/ai'.length).trim();
    }

    if (query.isEmpty) {
      return 'Tôi có thể giúp gì cho bạn? Thử gõ `@antigravity help` hoặc `@antigravity status`.';
    }

    final lower = query.toLowerCase();

    if (lower == 'help' ||
        lower.contains('tro giup') ||
        lower.contains('trợ giúp')) {
      return '''
[Lệnh Antigravity Bot]:
  • @antigravity status   - Xem trạng thái máy chủ, uptime và hệ điều hành
  • @antigravity time     - Xem ngày giờ hiện tại
  • @antigravity sysinfo  - Thông số chi tiết phần cứng & môi trường
  • @antigravity joke     - Một câu chuyện vui lập trình
  • @antigravity quote    - Câu danh ngôn công nghệ
  • @antigravity roll [n] - Tung xúc xắc ngẫu nhiên từ 1 đến n (mặc định: 6)
  • @antigravity echo <s> - Phản hồi lại chuỗi văn bản
  • @antigravity <câu hỏi>- Trả lời câu hỏi bất kỳ!
''';
    }

    if (lower == 'status' || lower == 'uptime') {
      final upStr = uptime != null
          ? '${uptime.inHours}h ${uptime.inMinutes.remainder(60)}m ${uptime.inSeconds.remainder(60)}s'
          : 'Đang hoạt động';
      return '🟢 Server Online | Uptime: $upStr | Người dùng đang kết nối: $connectedUsers | OS: ${Platform.operatingSystem} (${Platform.version.split(' ').first})';
    }

    if (lower == 'time' ||
        lower.contains('may gio') ||
        lower.contains('mấy giờ')) {
      final now = DateTime.now();
      return '🕒 Thời gian hiện tại: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    }

    if (lower == 'sysinfo' || lower == 'system') {
      return '💻 Máy chủ: ${Platform.localHostname} | Nhân CPU: ${Platform.numberOfProcessors} | OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion} | Dart: ${Platform.version.split(' ').first}';
    }

    if (lower == 'joke' || lower.contains('hai') || lower.contains('hài')) {
      final rand = Random();
      return '😄 ${_jokes[rand.nextInt(_jokes.length)]}';
    }

    if (lower == 'quote' ||
        lower.contains('danh ngon') ||
        lower.contains('danh ngôn')) {
      final rand = Random();
      return '💡 ${_quotes[rand.nextInt(_quotes.length)]}';
    }

    if (lower.startsWith('roll')) {
      final parts = lower.split(RegExp(r'\s+'));
      int maxVal = 6;
      if (parts.length > 1) {
        maxVal = int.tryParse(parts[1]) ?? 6;
      }
      final roll = Random().nextInt(maxVal) + 1;
      return '🎲 Bạn đã tung được số $roll (từ 1 đến $maxVal)!';
    }

    if (lower.startsWith('echo ')) {
      return query.substring(5).trim();
    }

    if (lower.contains('chào') ||
        lower.contains('hello') ||
        lower.contains('hi')) {
      return 'Chào bạn! Chúc bạn có một phiên làm việc hiệu quả trên terminal!';
    }

    if (lower.contains('antigravity la gi') ||
        lower.contains('antigravity là gì')) {
      return 'Antigravity là nền tảng Agentic AI thế hệ mới từ Google DeepMind, cho phép lập trình cặp đôi (pair programming) và điều phối công việc thông minh trên môi trường terminal/IDE!';
    }

    return 'Antigravity đã nhận tin nhắn: "$query". Bạn có thể gọi `@antigravity help` để khám phá các tính năng đặc biệt.';
  }
}
