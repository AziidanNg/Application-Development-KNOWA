// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/chat_service.dart';
import 'group_info_screen.dart'; // Make sure to import the new screen we created

class ChatScreen extends StatefulWidget {
  final int roomId;
  final String roomName;

  const ChatScreen({super.key, required this.roomId, required this.roomName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  
  List<dynamic> _messages = [];
  Map<String, dynamic>? _pinnedMessage; // Variable to store the pinned message
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Refresh messages every 3 seconds (Polling)
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final msgs = await _chatService.getMessages(widget.roomId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          // Find the latest message where 'is_pinned' is true (if any)
          // The backend should send 'is_pinned': true/false
          try {
            _pinnedMessage = msgs.firstWhere(
              (m) => m['is_pinned'] == true, 
              orElse: () => null
            );
          } catch (e) {
            _pinnedMessage = null;
          }
        });
      }
    } catch (e) {
      // Handle error silently during polling
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _chatService.sendMessage(widget.roomId, text);
    _fetchMessages(); // Refresh immediately
  }

  // Placeholder for Pinning Logic
  void _togglePinMessage(int messageId, bool currentStatus) async {
    // Call your API here to toggle pin status
    // await _chatService.pinMessage(messageId, !currentStatus);
    
    // For now, just print to console so you can see it works
    print("Pinning message $messageId. New status: ${!currentStatus}");
    _fetchMessages(); // Refresh to show changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        // 1. CLICKABLE HEADER FOR INFO
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupInfoScreen(
                  chatId: widget.roomId, 
                  chatName: widget.roomName
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(widget.roomName.isNotEmpty ? widget.roomName[0] : "?"),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.roomName, style: const TextStyle(fontSize: 16)),
                    const Text("Tap for group info", style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // 2. PINNED MESSAGE BANNER
          if (_pinnedMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.push_pin, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pinnedMessage!['content'] ?? "Pinned Message",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // 3. MESSAGE LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isPinned = msg['is_pinned'] ?? false;

                return GestureDetector(
                  // Long press to show Pin Option
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.push_pin),
                            title: Text(isPinned ? 'Unpin Message' : 'Pin Message'),
                            onTap: () {
                              Navigator.pop(context);
                              _togglePinMessage(msg['id'], isPinned);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPinned ? Colors.yellow[50] : Colors.grey[200], // Highlight if pinned
                      border: isPinned ? Border.all(color: Colors.orange.withOpacity(0.3)) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              msg['sender_name'] ?? 'Unknown', 
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800], fontSize: 12)
                            ),
                            if (isPinned) 
                              const Icon(Icons.push_pin, size: 12, color: Colors.orange)
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(msg['content'] ?? ''),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 4. INPUT FIELD
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...", 
                      border: OutlineInputBorder()
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}