// lib/screens/message_info_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/chat_service.dart';

class MessageInfoScreen extends StatefulWidget {
  final int messageId;
  const MessageInfoScreen({super.key, required this.messageId});

  @override
  State<MessageInfoScreen> createState() => _MessageInfoScreenState();
}

class _MessageInfoScreenState extends State<MessageInfoScreen> {
  final ChatService _service = ChatService();
  Map<String, dynamic>? _info;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  void _fetchInfo() async {
    try {
      final data = await _service.getMessageInfo(widget.messageId);
      setState(() { _info = data; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUserList(List<dynamic> users, IconData icon, Color color) {
    if (users.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text("No one yet"));
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index];
        return ListTile(
          leading: CircleAvatar(
             // --- FIX: Use Production URL here ---
             backgroundImage: u['avatar'] != null 
                 ? NetworkImage("https://knowa.up.railway.app${u['avatar']}") 
                 : null,
             child: u['avatar'] == null ? Text(u['username'][0]) : null,
          ),
          title: Text(u['username']),
          trailing: Icon(icon, color: color, size: 16),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Message Info")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _info == null 
          ? const Center(child: Text("Could not load info"))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message Bubble Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(_info!['message'], style: const TextStyle(fontSize: 16)),
                         const SizedBox(height: 5),
                         Text(
                           "Sent: ${_info!['timestamp'].toString().substring(0, 16).replaceAll('T', ' ')}", 
                           style: const TextStyle(color: Colors.grey, fontSize: 12)
                         ),
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text("Read By", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ),
                  _buildUserList(_info!['read_by'], Icons.done_all, Colors.blue),

                  const Divider(),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text("Delivered To", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  _buildUserList(_info!['delivered_to'], Icons.done, Colors.grey),
                ],
              ),
            ),
    );
  }
}