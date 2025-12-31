import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import '../models/faq_model.dart';

class GlobalChatbot extends StatefulWidget {
  final double additionalBottomPadding;

  const GlobalChatbot({
    super.key, 
    this.additionalBottomPadding = 0.0,
  });

  @override
  State<GlobalChatbot> createState() => _GlobalChatbotState();
}

class _GlobalChatbotState extends State<GlobalChatbot> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isOpen = false;
  bool _isLoading = false;
  List<Map<String, String>> _messages = [];
  List<FAQ> _faqs = [];

  @override
  void initState() {
    super.initState();
    _fetchFAQs();
  }

  void _fetchFAQs() async {
    try {
      final faqs = await _chatbotService.getFAQs();
      if (mounted) setState(() => _faqs = faqs);
    } catch (e) {
      print("FAQ Fetch Error: $e");
    }
  }

  Future<void> _handleMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await _chatbotService.sendMessage(text);
      if (mounted) {
        setState(() => _messages.add({'role': 'ai', 'text': reply}));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add({'role': 'ai', 'text': 'Connection Error.'}));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _onFAQClicked(FAQ faq) {
    setState(() {
      _messages.add({'role': 'user', 'text': faq.question});
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _messages.add({'role': 'ai', 'text': faq.answer}));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showFAQSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Common Questions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: _faqs.isEmpty
                ? const Center(child: Text("No common questions found."))
                : ListView.builder(
                    itemCount: _faqs.length,
                    itemBuilder: (context, index) {
                      final faq = _faqs[index];
                      return ListTile(
                        leading: const Icon(Icons.help_outline, color: Colors.orange),
                        title: Text(faq.question),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () {
                          Navigator.pop(context);
                          _onFAQClicked(faq);
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomOffset = 20 + MediaQuery.of(context).padding.bottom + widget.additionalBottomPadding;
    
    // CLOSED STATE
    if (!_isOpen) {
      return Positioned(
        bottom: bottomOffset,
        right: 20,
        child: FloatingActionButton(
          onPressed: () => setState(() => _isOpen = true),
          backgroundColor: Colors.blue.shade700,
          elevation: 6,
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
        ),
      );
    }

    // OPEN STATE
    return Positioned(
      bottom: bottomOffset,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: Container(
          width: 350,
          height: 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              // 1. MAIN HEADER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.smart_toy, color: Colors.white),
                        SizedBox(width: 8),
                        Text("KNOWA Assistant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _isOpen = false),
                    ),
                  ],
                ),
              ),

              // 2. NEW: FAQ BAR (Below Header)
              GestureDetector(
                onTap: _showFAQSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.orange.shade50, // Subtle highlight color
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "View Common FAQs", 
                          style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13)
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 12, color: Colors.orange.shade300),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // 3. CHAT HISTORY
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text("Ask me about events or tap the FAQ bar above.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              constraints: const BoxConstraints(maxWidth: 260),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(msg['text']!, style: const TextStyle(fontSize: 14)),
                            ),
                          );
                        },
                      ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Thinking...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),

              // 4. INPUT BAR (Cleaned up)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onSubmitted: (val) => _handleMessage(val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.blue.shade700),
                      onPressed: () => _handleMessage(_controller.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}