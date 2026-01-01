import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/chat_service.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({Key? key}) : super(key: key);

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _nameController = TextEditingController();
  
  List<dynamic> _availableUsers = [];
  final Set<int> _selectedIds = {}; // Stores IDs of selected users
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final users = await _chatService.getUserOptions();
    if (mounted) {
      setState(() {
        _availableUsers = users;
        _isLoading = false;
      });
    }
  }

  void _submit() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a chat name")));
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one user")));
      return;
    }

    setState(() => _isSubmitting = true);

    bool success = await _chatService.createChatRoom(
      _nameController.text,
      _selectedIds.toList(),
      'GENERAL', // Default type for admin chats
    );

    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true); // Return 'true' to indicate refresh needed
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create chat")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Chat", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: const Text("CREATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Chat Name Input
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Group / Chat Name",
                      hintText: "e.g. Planning Committee",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Select Participants", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),

                // 2. User List
                Expanded(
                  child: ListView.builder(
                    itemCount: _availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = _availableUsers[index];
                      final id = user['id'];
                      final isSelected = _selectedIds.contains(id);
                      final role = user['role'] ?? 'Member';

                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: Colors.blue,
                        title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(role),
                        secondary: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text(user['name'][0].toUpperCase()),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(id);
                            } else {
                              _selectedIds.remove(id);
                            }

                            // --- SMART NAME LOGIC ---
                            if (_selectedIds.isEmpty) {
                              // 1. No one selected -> Clear
                              _nameController.clear();
                            } 
                            else if (_selectedIds.length == 1) {
                              // 2. Exactly one person -> Auto-fill their name
                              // Find the user object for the single selected ID
                              final singleUser = _availableUsers.firstWhere((u) => u['id'] == _selectedIds.first);
                              _nameController.text = singleUser['name'];
                            } 
                            else {
                              // 3. More than one person (Group)
                              // We only clear if the current text matches one of the user names
                              // (This means it was likely auto-filled, not manually typed)
                              bool isAutoFilledName = _availableUsers.any((u) => u['name'] == _nameController.text);
                              
                              if (isAutoFilledName) {
                                _nameController.clear(); // Ready for group name!
                              }
                              // If user already typed "Cool Group", we leave it alone.
                            }
                            // -----------------------
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}