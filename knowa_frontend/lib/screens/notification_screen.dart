import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/notification_item.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final AuthService _authService = AuthService();
  late Future<List<NotificationItem>> _notifFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _notifFuture = _authService.getNotifications();
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'SUCCESS': return Icons.check_circle;
      case 'WARNING': return Icons.warning;
      case 'ERROR': return Icons.error;
      default: return Icons.info;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'SUCCESS': return Colors.green;
      case 'WARNING': return Colors.orange;
      case 'ERROR': return Colors.red;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<NotificationItem>>(
        future: _notifFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          final list = snapshot.data!;
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = list[index];
              return Container(
                color: item.isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                child: ListTile(
                  leading: Icon(_getIcon(item.type), color: _getColor(item.type)),
                  title: Text(
                    item.title, 
                    style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(item.message),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(item.createdAt.toLocal()),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!item.isRead) {
                      _authService.markNotificationRead(item.id);
                      setState(() {
                        // Optimistically update UI locally or just re-fetch
                        _refresh(); 
                      });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}