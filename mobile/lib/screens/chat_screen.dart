import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_socket_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatSocketService _service = ChatSocketService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<MobileChatMessage> _messages = [];
  List<String> _onlineUsers = [];
  ConnectionStatus _status = ConnectionStatus.disconnected;

  // Settings controllers
  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '4040');
  final _nameController = TextEditingController(text: 'AndroidUser');
  final _roomController = TextEditingController(text: '#general');

  @override
  void initState() {
    super.initState();

    _service.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });

    _service.messageStream.listen((msg) {
      if (mounted) {
        setState(() {
          _messages.add(msg);
        });
        _scrollToBottom();
      }
    });

    _service.usersStream.listen((users) {
      if (mounted) {
        setState(() => _onlineUsers = users);
      }
    });

    // Auto connect on start
    _connect();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _connect() async {
    try {
      await _service.connect(
        targetHost: _hostController.text.trim(),
        targetPort: int.tryParse(_portController.text.trim()) ?? 4040,
        targetUsername: _nameController.text.trim().isEmpty ? 'Android' : _nameController.text.trim(),
        targetRoom: _roomController.text.trim().isEmpty ? '#general' : _roomController.text.trim(),
      );
    } catch (_) {}
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _textController.text;
    if (text.trim().isEmpty) return;
    _service.sendMessage(text);
    if (customText == null) _textController.clear();
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '⚙️ Thiết lập kết nối máy chủ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ Host (Server IP / 127.0.0.1)',
                  prefixIcon: Icon(Icons.dns, color: Colors.cyanAccent),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cổng Port (Mặc định: 4040)',
                  prefixIcon: Icon(Icons.numbers, color: Colors.cyanAccent),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên của bạn',
                  prefixIcon: Icon(Icons.person, color: Colors.cyanAccent),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Phòng chat (ví dụ: #general, #dev)',
                  prefixIcon: Icon(Icons.tag, color: Colors.cyanAccent),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (_status == ConnectionStatus.connected) {
                      _service.disconnect();
                    }
                    _connect();
                  },
                  icon: const Icon(Icons.wifi_tethering),
                  label: Text(
                    _status == ConnectionStatus.connected ? 'Kết nối lại' : 'Kết nối máy chủ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUsersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('👥 Người dùng đang online', style: TextStyle(color: Colors.white)),
          content: _onlineUsers.isEmpty
              ? const Text('Chưa có ai khác kết nối.', style: TextStyle(color: Colors.white70))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _onlineUsers.map((u) {
                    return ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        backgroundColor: Colors.cyan,
                        radius: 12,
                        child: Icon(Icons.person, size: 14, color: Colors.black),
                      ),
                      title: Text(u, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng', style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              '⚡ Antigravity',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
              ),
              child: Text(
                _service.room,
                style: const TextStyle(fontSize: 12, color: Colors.cyanAccent),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Danh sách online',
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () {
              _service.sendMessage('/users');
              _showUsersDialog();
            },
          ),
          IconButton(
            tooltip: 'Cài đặt kết nối',
            icon: Icon(
              Icons.circle,
              size: 14,
              color: _status == ConnectionStatus.connected
                  ? Colors.greenAccent
                  : (_status == ConnectionStatus.connecting ? Colors.orangeAccent : Colors.redAccent),
            ),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection banner if disconnected
          if (_status != ConnectionStatus.connected)
            GestureDetector(
              onTap: _showSettings,
              child: Container(
                width: double.infinity,
                color: Colors.red.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orangeAccent),
                    const SizedBox(width: 6),
                    Text(
                      _status == ConnectionStatus.connecting
                          ? 'Đang kết nối tới ${_service.host}:${_service.port}...'
                          : 'Chưa kết nối máy chủ (${_service.host}:${_service.port}). Chạm để kết nối.',
                      style: const TextStyle(fontSize: 12, color: Colors.orangeAccent),
                    ),
                  ],
                ),
              ),
            ),

          // Chat messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.terminal, size: 64, color: Colors.cyan.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'Chào mừng đến với Antigravity Chat!',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Gõ tin nhắn bên dưới hoặc gọi @antigravity',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageTile(msg);
                    },
                  ),
          ),

          // Quick action chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _buildActionChip('🤖 @antigravity status', '@antigravity status'),
                _buildActionChip('🕒 @antigravity time', '@antigravity time'),
                _buildActionChip('🎲 @antigravity roll', '@antigravity roll'),
                _buildActionChip('😄 @antigravity joke', '@antigravity joke'),
                _buildActionChip('💡 @antigravity help', '@antigravity help'),
              ],
            ),
          ),

          // Input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn hoặc @antigravity...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.cyan, Color(0xFF8B5CF6)],
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, String command) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        backgroundColor: const Color(0xFF1E293B),
        labelStyle: const TextStyle(fontSize: 12, color: Colors.cyanAccent),
        label: Text(label),
        onPressed: () => _sendMessage(command),
      ),
    );
  }

  Widget _buildMessageTile(MobileChatMessage msg) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Text(
            '⚡ ${msg.text}',
            style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
          ),
        ),
      );
    }

    final isMe = msg.sender == _service.username;

    if (msg.isBot) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E38),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.purpleAccent.withOpacity(0.5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.purpleAccent,
                  radius: 10,
                  child: Icon(Icons.smart_toy, size: 12, color: Colors.black),
                ),
                const SizedBox(width: 6),
                const Text(
                  '🤖 Antigravity AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purpleAccent,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)])
              : const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg.sender,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 9,
                color: isMe ? Colors.white60 : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }
}
