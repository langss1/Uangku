import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isTyping = false;
  late final ChatSession _chatSession;

  // Data Pesan
  final List<Map<String, dynamic>> _messages = [
    {
      'isTop': true,
      'isUser': false,
      'text': 'Halo! Saya UANGKU AI, asisten keuangan pribadi Anda. Bagaimana saya bisa membantu mengelola keuangan Anda hari ini?',
      'time': '09:30',
    },
  ];

  late AnimationController _typingAnimCtrl;

  @override
  void initState() {
    super.initState();
    _typingAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
    );
    
    // History harus dimulai dari user, jadi kita kosongkan saja history awalnya.
    // Pesan sapaan pertama cukup tampil di UI saja.
    _chatSession = model.startChat();
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
      // Inject persona ke pesan pertama secara manual untuk menghindari bug systemInstruction di SDK lama
      String prompt = newMsg;
      if (_messages.length <= 2) { 
        prompt = "System Prompt: Kamu adalah UANGKU AI, penasihat dan asisten ahli keuangan pribadi pengguna. Berikan saran alokasi budgeting, investasi, dan analisis pengeluaran dalam bahasa Indonesia yang ringkas, profesional, dan bersahabat. Hindari pengatur paragraf ganda. Jangan mengaku sebagai AI biasa.\n\nPertanyaan User: $newMsg";
      }

      final response = await _chatSession.sendMessage(Content.text(prompt));
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'isTop': false,
          'isUser': false,
          'text': response.text?.trim() ?? 'Maaf, saya tidak dapat merespons saat ini.',
          'time': _getCurrentTime(),
        });
      });
      _scrollToBottom();
    } catch (e) {
      print('Chatbot Error: $e'); // Print error ke console
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'isTop': false,
          'isUser': false,
          'text': 'Error detail:\n$e',
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
                  Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
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
