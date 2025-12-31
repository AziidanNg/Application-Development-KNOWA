// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/chat_service.dart';
import 'group_info_screen.dart';
import 'message_info_screen.dart';

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
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];
  Map<String, dynamic>? _pinnedMessage;
  Timer? _timer;
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages());

    // SCROLL LISTENER FIX
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      
      // Logic: Show button if we are NOT at the bottom (user scrolled up)
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      
      // If user is more than 300 pixels away from the bottom, show button
      if (maxScroll - currentScroll > 300) {
        if (!_showScrollButton) setState(() => _showScrollButton = true);
      } else {
        if (_showScrollButton) setState(() => _showScrollButton = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final msgs = await _chatService.getMessages(widget.roomId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          try {
            _pinnedMessage = msgs.firstWhere((m) => m['is_pinned'] == true, orElse: () => null);
          } catch (e) {
            _pinnedMessage = null;
          }
        });
        _chatService.markMessagesAsRead(widget.roomId);
      }
    } catch (e) {
      // Silent error
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _chatService.sendMessage(widget.roomId, text);
    _fetchMessages();
    
    // Auto scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToPinnedMessage() {
    if (_pinnedMessage == null) return;
    final index = _messages.indexWhere((m) => m['id'] == _pinnedMessage!['id']);
    if (index != -1) {
      double offset = index * 70.0; 
      if (_scrollController.hasClients) {
         _scrollController.jumpTo(offset); // Zero delay
      }
    }
  }

  void _togglePinMessage(int messageId) async {
    try {
      await _chatService.togglePinMessage(messageId);
      _fetchMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to pin message")));
    }
  }

  Widget _buildDoubleTick(bool isRead) {
    return Icon(
      Icons.done_all, 
      size: 16, 
      // Use Primary Color for read, Grey for unread
      color: isRead ? Theme.of(context).primaryColor : Colors.grey
    );
  }

  @override
  Widget build(BuildContext context) {
    // GET SYSTEM COLORS
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Colors.grey[100]; // Neutral background

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        // 2. DARKER COLOR: You can use a specific dark teal or your primary color
        // OR use your theme: Theme.of(context).primaryColorDark,
        backgroundColor: darken(Theme.of(context).primaryColor, 0.01),
        iconTheme: const IconThemeData(color: Colors.white),
        title: InkWell(
          onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (c) => GroupInfoScreen(chatId: widget.roomId, chatName: widget.roomName))
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(widget.roomName.isNotEmpty ? widget.roomName[0] : "?", style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.roomName, style: const TextStyle(fontSize: 16)),
                  const Text("Tap for info", style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ),
      
      // 1. Move to the Bottom Right (Standard standard)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // 2. Add padding to push it up above the text box
      floatingActionButton: _showScrollButton 
          ? Padding(
              // 'bottom: 80' clears the text input area
              // 'right: 10' keeps it slightly away from the edge
              padding: const EdgeInsets.only(bottom: 80, right: 10), 
              child: SizedBox(
                height: 40, // Force a small size
                width: 40,
                child: FloatingActionButton(
                  mini: true, // Makes the button smaller
                  backgroundColor: Colors.white,
                  elevation: 4, // Shadow to make it stand out
                  shape: const CircleBorder(), // Ensures it is round
                  child: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                  onPressed: _scrollToBottom,
                ),
              ),
            )
          : null,

      body: Column(
        children: [
          // PINNED BANNER
          if (_pinnedMessage != null)
            InkWell(
              onTap: _scrollToPinnedMessage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Icon(Icons.push_pin, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text("Pinned: ${_pinnedMessage!['content']}", 
                        maxLines: 1, overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))
                    ),
                  ],
                ),
              ),
            ),

          // CHAT LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final DateTime msgDate = DateTime.parse(msg['timestamp']);
                final primaryColor = Theme.of(context).primaryColor; // Get theme color

                // 1. DATE SEPARATOR LOGIC
                bool showDateHeader = false;
                if (i == 0) {
                  showDateHeader = true; // First message always gets a date
                } else {
                  final DateTime prevDate = DateTime.parse(_messages[i - 1]['timestamp']);
                  if (!isSameDay(msgDate, prevDate)) {
                    showDateHeader = true; // New day detected
                  }
                }

                // Variable Setup
                final bool isMe = msg['is_me'] ?? false;
                final bool isPinned = msg['is_pinned'] ?? false;
                // Remove 'T' from time string if present
                final String time = msg['timestamp'].toString().substring(11, 16); 

                // 2. RETURN A COLUMN (To hold both Date + Message)
                return Column(
                  children: [
                    // A. The Date Header (Only if needed)
                    if (showDateHeader)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          formatDateLabel(msgDate), // Uses the helper function
                          style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),

                    // B. The Message Bubble
                    GestureDetector(
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context, 
                          builder: (c) => Wrap(
                            children: [
                              // Pin Option
                              ListTile(
                                leading: const Icon(Icons.push_pin),
                                title: Text(isPinned ? 'Unpin Message' : 'Pin Message'),
                                onTap: () { 
                                  Navigator.pop(context); 
                                  _togglePinMessage(msg['id']); 
                                }
                              ),
                              // Info Option (Only if isMe)
                              if (isMe)
                                ListTile(
                                  leading: const Icon(Icons.info_outline),
                                  title: const Text("Message Info"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context, 
                                      MaterialPageRoute(builder: (c) => MessageInfoScreen(messageId: msg['id']))
                                    );
                                  }
                                ),
                            ],
                          )
                        );
                      },
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? primaryColor.withOpacity(0.1) : Colors.white,
                            border: isPinned ? Border.all(color: Colors.orange) : null,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sender Name (Only for others)
                              if (!isMe)
                                Text(
                                  msg['sender_name'] ?? 'User', 
                                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12)
                                ),

                              // Message Content
                              Text(msg['content'] ?? '', style: const TextStyle(fontSize: 16)),

                              const SizedBox(height: 4),
                              
                              // Time & Ticks
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    _buildDoubleTick(msg['is_read'] ?? false),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // INPUT AREA
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: primaryColor, // Matches System Theme
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to make any color darker
Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}

// Check if two dates are on the same day
bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year && 
         date1.month == date2.month && 
         date1.day == date2.day;
}

// Format date nicely
String formatDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final dateToCheck = DateTime(date.year, date.month, date.day);

  if (isSameDay(dateToCheck, today)) return "Today";
  if (isSameDay(dateToCheck, yesterday)) return "Yesterday";
  // Fallback: DD/MM/YYYY
  return "${date.day}/${date.month}/${date.year}";
}