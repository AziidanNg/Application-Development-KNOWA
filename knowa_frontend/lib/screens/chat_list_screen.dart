// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this to pubspec.yaml if missing
import 'package:knowa_frontend/services/chat_service.dart';
import 'package:knowa_frontend/screens/chat_screen.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/create_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  
  // --- NEW: Add Auth Service ---
  final AuthService _authService = AuthService(); // Make sure AuthService is imported
  
  // Data Variables
  List<dynamic> _allChatRooms = [];
  List<dynamic> _filteredChatRooms = [];
  bool _isLoading = true;
  
  // --- NEW: Admin Check Variable ---
  bool _isAdmin = false; 

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; 

  @override
  void initState() {
    super.initState();
    _checkAdminStatus(); // <--- Check permissions first
    _fetchChatRooms();
  }

  // --- NEW: Check Admin Status ---
  void _checkAdminStatus() async {
    final userData = await _authService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _isAdmin = userData['is_staff'] ?? false; // Check if staff
      });
    }
  }

  Future<void> _fetchChatRooms() async {
    try {
      final rooms = await _chatService.getChatRooms();
      if (mounted) {
        setState(() {
          _allChatRooms = rooms;
          _filteredChatRooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading chats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... (Keep _filterChats logic the same) ...
  void _filterChats() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredChatRooms = _allChatRooms.where((chat) {
        final name = (chat['name'] ?? chat['title'] ?? '').toString().toLowerCase();
        bool matchesSearch = name.contains(query);
        
        bool matchesFilter = true;
        if (_selectedFilter != 'All') {
          String type = (chat['type'] ?? '').toString().toUpperCase();
          matchesFilter = type == _selectedFilter.toUpperCase();
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "My Chats",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // --- UPDATED: Only show button if Admin ---
          if (_isAdmin) 
            IconButton(
              icon: const Icon(Icons.add_comment_outlined, color: Colors.blue),
              onPressed: () async {
                // Navigate to Create Screen
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateChatScreen()),
                );

                // If result is true, it means we created a chat -> Refresh list
                if (result == true) {
                   _fetchChatRooms();
                }
              },
            ),
        ],
      ),
      // ... (Rest of body remains exactly the same) ...
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterChats(),
              decoration: InputDecoration(
                hintText: "Search chats...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Interview'),
                const SizedBox(width: 8),
                _buildFilterChip('Event'),
                const SizedBox(width: 8),
                _buildFilterChip('Crew'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChatRooms.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredChatRooms.length,
                        itemBuilder: (context, index) {
                          return _buildChatTile(_filteredChatRooms[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ... (Keep _buildFilterChip, _buildChatTile, _buildEmptyState, helpers same) ...
  // Be sure to include the imports:
  // import 'package:knowa_frontend/services/auth_service.dart';
  
  // (Paste the rest of your existing helper methods here)
  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
          _filterChats();
        });
      },
      selectedColor: Colors.blue.shade100,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade900 : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildChatTile(dynamic chat) {
    // Extract Data Safely
    final chatName = chat['name'] ?? chat['title'] ?? 'Unknown Chat';
    final chatId = chat['id'];
    final String type = chat['type'] ?? 'GENERAL';
    final String lastMessage = chat['last_message'] ?? ''; 
    final String? timestamp = chat['last_message_time']; 

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              roomId: chatId,
              roomName: chatName,
            ),
          ),
        );
        _fetchChatRooms();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: _getAvatarColor(type),
              child: Text(
                chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chatName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.isNotEmpty ? lastMessage : "Tap to start chatting",
                    style: TextStyle(
                      fontSize: 14, 
                      color: Colors.grey[600],
                      fontStyle: lastMessage.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No chats found",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String type) {
    switch (type.toUpperCase()) {
      case 'INTERVIEW': return Colors.blue;
      case 'EVENT': return Colors.purple;
      case 'CREW': return Colors.orange;
      default: return Colors.blueGrey;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return "";
    try {
      DateTime date = DateTime.parse(timestamp);
      DateTime now = DateTime.now();

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return DateFormat('h:mm a').format(date);
      }
      
      if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        return "Yesterday";
      }

      return DateFormat('MMM d').format(date);
    } catch (e) {
      return "";
    }
  }
}