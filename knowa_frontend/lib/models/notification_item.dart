class NotificationItem {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String type; // INFO, SUCCESS, WARNING, ERROR

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.type,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
      type: json['notification_type'] ?? 'INFO',
    );
  }
}