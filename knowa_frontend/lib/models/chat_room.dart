class ChatRoom {
  final int id;
  final String name;
  final String type; // 'INTERVIEW', 'EVENT', 'CREW'
  final String lastMessage;
  final String? lastMessageTime;

  ChatRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'] ?? 'Chat',
      type: json['type'] ?? 'GENERAL',
      // Safely handle nulls if backend update isn't live yet
      lastMessage: json['last_message'] ?? '', 
      lastMessageTime: json['last_message_time'],
    );
  }
}