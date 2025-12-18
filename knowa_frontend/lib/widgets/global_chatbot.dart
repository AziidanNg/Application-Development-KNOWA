// lib/widgets/global_chatbot.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For platform check

class GlobalChatbot extends StatefulWidget {
  final double additionalBottomPadding;

  const GlobalChatbot({
    super.key, 
    this.additionalBottomPadding = 0.0, // Default is 0
  });

  @override
  State<GlobalChatbot> createState() => _GlobalChatbotState();
}

class _GlobalChatbotState extends State<GlobalChatbot> {
  bool _isOpen = false; // Is the chat window open?
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // Correct URL for Emulator vs Device
  final String _baseUrl = defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000/api/users/chatbot/'
      : 'http://127.0.0.1:8000/api/users/chatbot/';

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({'role': 'ai', 'text': data['reply']});
        });
      } else {
        setState(() {
          _messages.add({'role': 'ai', 'text': 'Error connecting to server.'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Connection failed. Is server running?'});
      });
    } finally {
      setState(() {
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double bottomOffset = 20 + bottomPadding + widget.additionalBottomPadding;
    
    // If chat is NOT open, show button
    if (!_isOpen) {
      return Positioned(
        bottom: bottomOffset, // <--- UPDATED
        right: 20,
        child: FloatingActionButton(
          onPressed: () => setState(() => _isOpen = true),
          backgroundColor: Colors.blue.shade700,
          elevation: 6,
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
        ),
      );
    }

    // If chat IS open, show window
    return Positioned(
      bottom: bottomOffset, // <--- UPDATED
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
              // ... (Rest of your header, chat list, and input code remains exactly the same) ...
              // Header
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
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _isOpen = false),
                    ),
                  ],
                ),
              ),

              // Chat List
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text("Hi! Ask me anything about registration, login, or events.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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

              // Loading
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Thinking...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),

              // Input
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
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.blue.shade700),
                      onPressed: _sendMessage,
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