// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/chat_service.dart';
import 'package:knowa_frontend/screens/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  late Future<List<dynamic>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _roomsFuture = _chatService.getChatRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Chats")),
      body: FutureBuilder<List<dynamic>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No chats joined yet."));

          final rooms = snapshot.data!;
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (ctx, i) {
              final room = rooms[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.group)),
                title: Text(room['room_name'] ?? 'Chat'),
                subtitle: Text(room['last_message'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(roomId: room['id'], roomName: room['room_name']),
                    ),
                  ).then((_) => _refresh());
                },
              );
            },
          );
        },
      ),
    );
  }
}