class ChatUser {
  final int id;
  final String username;
  final String? avatar;
  final String role; // 'admin', 'crew', 'member'

  ChatUser({
    required this.id, 
    required this.username, 
    this.avatar, 
    this.role = 'member'
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'],
      username: json['username'],
      avatar: json['avatar'],
      role: json['role'] ?? 'member', 
    );
  }
}

class ChatMessage {
  final int id;
  final String content;
  final int senderId;
  final String senderName;
  final bool isPinned;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.isPinned,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      senderId: json['sender'] is int ? json['sender'] : 0, // Safety check
      senderName: json['sender_name'] ?? 'User',
      isPinned: json['is_pinned'] ?? false, 
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}