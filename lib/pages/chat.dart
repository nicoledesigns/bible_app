import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BiblicalChatPage extends StatefulWidget {
  const BiblicalChatPage({super.key});

  @override
  State<BiblicalChatPage> createState() => _BiblicalChatPageState();
}

class _BiblicalChatPageState extends State<BiblicalChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  String _translation = 'ESV';

  final List<_ChatMessage> _messages = <_ChatMessage>[
    _ChatMessage(
      role: 'assistant',
      content:
          'Hi! I\'m your Christian AI. Ask me anything — I\'ll answer with Scripture and gentle guidance.',
    ),
  ];

  // ✅ Fixed string concatenation
  String get _systemPrompt =>
      'You are a Christian assistant who answers with a pastoral, humble tone. '
      'Base your guidance on the Bible first and foremost. When you give an answer: '
      '1) Start with a brief summary. 2) Support with 2–4 relevant Scripture references. '
      '3) Show references as Book Chapter:Verse (e.g., John 3:16) and, when helpful, include short quotations. '
      '4) If a topic is sensitive (medical, legal, mental health, self-harm, abuse), encourage seeking qualified help and pastoral counsel. '
      '5) Stay concise and practical, avoid speculation. '
      '6) Use $_translation translation conventions when quoting or paraphrasing. '
      '7) If a question is outside biblical scope, apply biblical principles or say you do not know rather than guessing.';

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _sending = true;
      _controller.clear();
    });

    try {
      final reply = await _callLLM(_messages);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: reply));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _sending = false);
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }
  @override
void initState() {
  super.initState();
}


  Future<String> _callLLM(List<_ChatMessage> history) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY is missing. Create a .env file and load it in main().');
    }

    final baseUrl = dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
    final model = dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';

    final uri = Uri.parse('$baseUrl/chat/completions');

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt},
      ...history.map((m) => m.toJson()),
    ];

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 800,
      }),
    );

    if (res.statusCode ~/ 100 != 2) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;

    if (choices == null || choices.isEmpty) {
      throw Exception('No response from the AI');
    }

    final msg = choices.first['message'] as Map<String, dynamic>? ?? {};
    final content = (msg['content'] ?? '').toString().trim();

    if (content.isEmpty) {
      throw Exception('Empty response from the AI');
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Christian AI — Biblical Answers'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _translation,
                onChanged: (v) => setState(() => _translation = v ?? 'ESV'),
                items: const [
                  DropdownMenuItem(value: 'ESV', child: Text('ESV')),
                  DropdownMenuItem(value: 'NIV', child: Text('NIV')),
                  DropdownMenuItem(value: 'KJV', child: Text('KJV')),
                  DropdownMenuItem(value: 'NKJV', child: Text('NKJV')),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  final isUser = m.role == 'user';
                  return _MessageBubble(message: m, isUser: isUser);
                },
              ),
            ),
            const Divider(height: 1),
            _Composer(
              controller: _controller,
              sending: _sending,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 6,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Ask a question (e.g., “What does the Bible say about worry?”)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: sending ? null : onSend,
            icon: const Icon(Icons.send),
            label: Text(sending ? 'Sending…' : 'Send'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isUser;
  const _MessageBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final bg = isUser ? Theme.of(context).colorScheme.primary : Colors.grey[200];
    final fg = isUser ? Colors.white : Colors.black87;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: radius, boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ]),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: SelectableText(
              message.content,
              style: TextStyle(color: fg, fontSize: 16, height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  _ChatMessage({required this.role, required this.content});
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
