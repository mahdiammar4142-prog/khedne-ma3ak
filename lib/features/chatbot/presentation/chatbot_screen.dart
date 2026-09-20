import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lebanon_places/features/chatbot/data/ai_chat_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = AiChatService();
  final List<({String text, bool isUser, bool isFallback})> _messages = [
    (
      text:
          'Hi! I\'m your Khedne Ma3ak assistant. Ask me for recommendations (e.g. "best burgers in Beirut", "pool with a view"), or type "guide" for the place guide.',
      isUser: false,
      isFallback: false,
    ),
  ];
  bool _isLoading = false;
  bool _usingFallback = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add((text: text, isUser: true, isFallback: false));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final aiResult = await _aiService.sendMessageDetailed(text);
    final useFallback = !aiResult.isSuccess;
    final reply = aiResult.reply ?? _fallbackReply(text);

    if (mounted) {
      setState(() {
        _usingFallback = useFallback;
        _messages.add((text: reply, isUser: false, isFallback: useFallback));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fallbackReply(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('guide')) {
      return 'Open the Guide from the home screen to browse places by category and region. You can also search from the search tab and use filters.';
    }
    if (lower.contains('burger') || lower.contains('restaurant') || lower.contains('food')) {
      return 'Try searching "burgers" or "restaurant" in Search — we\'ll show restaurants and snack places. In Beirut, Roadster Diner is a popular choice!';
    }
    if (lower.contains('pool') || lower.contains('beach')) {
      return 'Search "pool" or "beach" for pools and beach clubs. Le Bristol Pool and Mövenpick are great options.';
    }
    if (lower.contains('hotel') || lower.contains('stay')) {
      return 'Search "hotel" or "resort" for stays. Many places support booking — tap a place then "Book / Plan trip".';
    }
    if (lower.contains('trip') || lower.contains('plan')) {
      return 'Use the Trip planning section from the home screen to plan and book trips.';
    }
    return 'I can help with food, pools, hotels, and trip planning. Try: "best burgers", "pool in Beirut", or "guide".';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101615),
        title: const Text('Chatbot'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _StatusBanner(
            modeLabel: _aiService.modeLabel,
            usingFallback: _usingFallback,
          ),
          const SizedBox(height: 4),
          _QuickPrompts(
            onPrompt: (prompt) {
              _controller.text = prompt;
              _send();
            },
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Thinking...',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final m = _messages[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? const Color(0xFF00A651)
                          : m.isFallback
                              ? const Color(0xFFFFF3E0)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: m.isUser
                            ? const Color(0xFF00A651)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: m.isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.black87),
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Ask for recommendations...',
                        hintStyle: const TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF00A651)),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF00A651),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String modeLabel;
  final bool usingFallback;

  const _StatusBanner({
    required this.modeLabel,
    required this.usingFallback,
  });

  @override
  Widget build(BuildContext context) {
    final isHealthy = !usingFallback;
    final bg = isHealthy ? Colors.green.shade50 : Colors.orange.shade50;
    final border = isHealthy ? Colors.green.shade200 : Colors.orange.shade200;
    final icon = isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded;
    final color = isHealthy ? Colors.green.shade800 : Colors.orange.shade900;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isHealthy
                    ? '$modeLabel connected'
                    : 'Using built-in replies right now. AI connection is temporarily unavailable.',
                style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPrompts extends StatelessWidget {
  final void Function(String prompt) onPrompt;

  const _QuickPrompts({required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    const prompts = [
      'Best burgers in Beirut',
      'Pool with a view',
      'Hotel for weekend',
      'Guide',
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          return ActionChip(
            avatar: const Icon(Icons.bolt_rounded, size: 16, color: Colors.black87),
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade300),
            labelStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            label: Text(prompts[i]),
            onPressed: () => onPrompt(prompts[i]),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: prompts.length,
      ),
    );
  }
}
