// lib/screens/group_info_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/chat_model.dart';
import 'package:knowa_frontend/services/chat_service.dart';
import 'package:knowa_frontend/services/auth_service.dart';

class GroupInfoScreen extends StatefulWidget {
  final int chatId;
  final String chatName;

  const GroupInfoScreen({Key? key, required this.chatId, required this.chatName}) : super(key: key);

  @override
  _GroupInfoScreenState createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  bool isLoading = true;
  List<ChatUser> participants = [];
  List<ChatMessage> pinnedMessages = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    fetchGroupDetails();
  }

  void _checkAdminStatus() async {
    final userData = await _authService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _isAdmin = userData['is_staff'] ?? false;
      });
    }
  }

  Future<void> fetchGroupDetails() async {
    try {
      final data = await _chatService.getGroupDetails(widget.chatId);
      
      if (mounted) {
        setState(() {
          participants = (data['participants'] as List).map((i) => ChatUser.fromJson(i)).toList();
          pinnedMessages = (data['pinned_messages'] as List).map((i) => ChatMessage.fromJson(i)).toList();
          // eventImage removed since we aren't using it
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching group info: $e");
      setState(() => isLoading = false);
    }
  }

  void _deleteChat() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Chat?"),
        content: const Text(
          "This will permanently delete this chat room and all messages for everyone.\n\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => isLoading = true);

    bool success = await _chatService.deleteChatRoom(widget.chatId);

    if (success && mounted) {
      Navigator.pop(context); 
      Navigator.pop(context); 
    } else {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete chat.")),
        );
      }
    }
  }

  Widget _buildRoleBadge(String role) {
    if (role == 'member') return SizedBox.shrink();

    Color color = role == 'admin' ? Colors.red : Colors.blue;
    String text = role == 'admin' ? "ADMIN" : "CREW";

    return Container(
      margin: EdgeInsets.only(left: 8),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Group Info"),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // --- REMOVED IMAGE CONTAINER ---
                  
                  const SizedBox(height: 30), // Added top spacing

                  // 1. Group Name & Count
                  Text(
                    widget.chatName, 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "${participants.length} Participants", 
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Divider(thickness: 1),

                  // 2. Pinned Messages Section
                  if (pinnedMessages.isNotEmpty) ...[
                    ListTile(
                      leading: Icon(Icons.push_pin, color: Colors.orange),
                      title: Text("${pinnedMessages.length} Pinned Messages"),
                      subtitle: Text(pinnedMessages.first.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Divider(),
                  ],

                  // 3. Participants List
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      "PARTICIPANTS", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.grey[700],
                        fontSize: 13,
                        letterSpacing: 0.5
                      )
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final user = participants[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50, // Added background color
                          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                          child: user.avatar == null ? Text(user.username[0].toUpperCase()) : null,
                        ),
                        title: Row(
                          children: [
                            Text(user.username, style: TextStyle(fontWeight: FontWeight.bold)),
                            _buildRoleBadge(user.role), 
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // 4. DELETE BUTTON (Admin Only)
                  if (_isAdmin)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _deleteChat,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text(
                            "Delete Chat Room",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}