import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isTyping = false;

  // Data Pesan — diinisialisasi di initState agar bisa pakai jam aktual
  final List<Map<String, dynamic>> _messages = [];

  late AnimationController _typingAnimCtrl;

  @override
  void initState() {
    super.initState();
    _typingAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Tambahkan pesan pembuka dengan jam aktual
    _messages.add({
      'isTop': true,
      'isUser': false,
      'text': 'Halo! Saya UANGKU AI, asisten keuangan pribadi Anda. Bagaimana saya bisa membantu mengelola keuangan Anda hari ini?',
      'time': _getCurrentTime(),
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _typingAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    final newMsg = _msgController.text.trim();
    _msgController.clear();

    setState(() {
      _messages.add({
        'isTop': false,
        'isUser': true,
        'text': newMsg,
        'time': _getCurrentTime(),
      });
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
      if (baseUrl.isEmpty) {
        print("Error: API_BASE_URL not found in .env");
      }
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      print("DEBUG: Mengirim request dengan token: '\$token'");

      final response = await http.post(
        Uri.parse('$baseUrl/api/data/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userMessage': newMsg,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isTyping = false;
          _messages.add({
            'isTop': false,
            'isUser': false,
            'text': data['reply'] ?? 'Maaf, respons tidak terbaca.',
            'time': _getCurrentTime(),
          });
        });
      } else {
        setState(() {
          _isTyping = false;
          _messages.add({
            'isTop': false,
            'isUser': false,
            'text': 'Gagal menghubungi server (Status: ${response.statusCode})',
            'time': _getCurrentTime(),
          });
        });
      }
      _scrollToBottom();
    } catch (e) {
      print('Chatbot Error: $e');
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'isTop': false,
          'isUser': false,
          'text': 'Error koneksi:\n$e',
          'time': _getCurrentTime(),
        });
      });
      _scrollToBottom();
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200, // extra extent for chips
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final msg = _messages[index];
                  return _buildMessageBubble(
                    text: msg['text'],
                    isUser: msg['isUser'],
                    time: msg['time'],
                  );
                } else {
                  return _buildTypingIndicator();
                }
              },
            ),
          ),
          _buildSuggestionChips(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF5A45FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UANGKU AI',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Row(
                children: const [
                  Text(
                    'Powered by ',
                    style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Gemini',
                    style: TextStyle(color: Color(0xFF2962FF), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.star, color: Colors.amber, size: 10), // Placeholder gemini icon
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black54),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: Colors.grey.shade200, height: 1.0),
      ),
    );
  }

  Widget _buildMessageBubble({required String text, required bool isUser, required String time}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF5A45FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2048BB) : const Color(0xFFF1F5F9), // Dark blue or grey
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: text,
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        strong: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A45FF),
                        ),
                        em: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                        h2: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                        listBullet: const TextStyle(
                          color: Color(0xFF5A45FF),
                          fontSize: 14,
                        ),
                        blockquote: const TextStyle(
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                        horizontalRuleDecoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.black45,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.black54, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF5A45FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimCtrl,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return Opacity(
                      opacity: _typingAnimCtrl.value > (index * 0.33) ? 1.0 : 0.3,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.0),
                        child: Icon(Icons.circle, size: 6, color: Colors.black54),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      {'label': 'Analyze my spending', 'color': const Color(0xFF2962FF)},
      {'label': 'Budget tips', 'color': const Color(0xFF059669)},
      {'label': 'Investment advice', 'color': const Color(0xFF7C3AED)},
      {'label': 'Savings goal', 'color': const Color(0xFFD97706)},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((s) {
            final color = s['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
              child: GestureDetector(
                onTap: () {
                  _msgController.text = s['label'] as String;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    border: Border.all(color: color.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s['label'] as String,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1.0),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic, color: Color(0xFF2962FF)),
                      onPressed: () {},
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF2962FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
