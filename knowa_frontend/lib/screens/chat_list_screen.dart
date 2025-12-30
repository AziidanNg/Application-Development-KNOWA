// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/chat_service.dart';
import 'package:knowa_frontend/screens/chat_screen.dart'; // Ensure this path is correct

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  List<dynamic> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatRooms();
  }

  Future<void> _fetchChatRooms() async {
    try {
      final rooms = await _chatService.getChatRooms();
      if (mounted) {
        setState(() {
          _chatRooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading chats: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Chats"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? const Center(child: Text("No chats yet"))
              : ListView.builder(
                  itemCount: _chatRooms.length,
                  itemBuilder: (context, index) {
                    final chat = _chatRooms[index];
                    
                    // --- SAFETY CHECK HERE ---
                    // We use '??' to provide a fallback if the data is null
                    final chatName = chat['name'] ?? chat['title'] ?? 'Unknown Chat';
                    final chatId = chat['id'];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            chatName.isNotEmpty ? chatName[0] : "?", 
                            style: const TextStyle(color: Colors.white)
                          ),
                        ),
                        title: Text(
                          chatName, 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to the Chat Screen we created earlier
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                roomId: chatId,
                                roomName: chatName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}