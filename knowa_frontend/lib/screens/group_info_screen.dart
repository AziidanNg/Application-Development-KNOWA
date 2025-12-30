// lib/screens/group_info_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/chat_model.dart';
import 'package:knowa_frontend/services/chat_service.dart';

class GroupInfoScreen extends StatefulWidget {
  final int chatId;
  final String chatName;

  const GroupInfoScreen({Key? key, required this.chatId, required this.chatName}) : super(key: key);

  @override
  _GroupInfoScreenState createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final ChatService _chatService = ChatService();
  bool isLoading = true;
  List<ChatUser> participants = [];
  List<ChatMessage> pinnedMessages = [];
  String? eventImage;

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
  }

  Future<void> fetchGroupDetails() async {
    try {
      // 2. Call the service (You might need to add this method to ChatService first)
      final data = await _chatService.getGroupDetails(widget.chatId);
      
      if (mounted) {
        setState(() {
          // Assuming your service returns a Map with these keys
          participants = (data['participants'] as List).map((i) => ChatUser.fromJson(i)).toList();
          pinnedMessages = (data['pinned_messages'] as List).map((i) => ChatMessage.fromJson(i)).toList();
          eventImage = data['event_image'];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching group info: $e");
      setState(() => isLoading = false);
    }
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      participants = [
        ChatUser(id: 1, username: "OrganizerUser", role: "admin"),
        ChatUser(id: 2, username: "CrewMate", role: "crew"),
        ChatUser(id: 3, username: "NormalUser", role: "member"),
      ];
      isLoading = false;
    });
  }

  // --- THE BADGE WIDGET ---
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
      appBar: AppBar(title: Text("Group Info")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 1. Header Image
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: eventImage != null 
                        ? Image.network(eventImage!, fit: BoxFit.cover)
                        : Icon(Icons.event, size: 80, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 10),
                  Text(widget.chatName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("${participants.length} Participants", style: TextStyle(color: Colors.grey)),
                  Divider(),

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
                    padding: EdgeInsets.all(16),
                    child: Text("Participants", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final user = participants[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                          child: user.avatar == null ? Text(user.username[0]) : null,
                        ),
                        title: Row(
                          children: [
                            Text(user.username, style: TextStyle(fontWeight: FontWeight.bold)),
                            _buildRoleBadge(user.role), // SHOW BADGE
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}