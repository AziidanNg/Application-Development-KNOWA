// lib/screens/admin_feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final AuthService _authService = AuthService();
  Future<List<Map<String, dynamic>>>? _feedbackFuture;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  void _loadFeedback() {
    setState(() {
      _feedbackFuture = _authService.getAllFeedback();
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'BUG': return Colors.red.shade50;
      case 'FEATURE': return Colors.purple.shade50;
      case 'IMPROVEMENT': return Colors.green.shade50;
      default: return Colors.grey.shade50;
    }
  }
  
  Color _getCategoryTextColor(String category) {
    switch (category) {
      case 'BUG': return Colors.red.shade900;
      case 'FEATURE': return Colors.purple.shade900;
      case 'IMPROVEMENT': return Colors.green.shade900;
      default: return Colors.grey.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. GET SYSTEM PADDING (Navigation Bar Height)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("User Feedback", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedback,
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _feedbackFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No feedback yet", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final feedbackList = snapshot.data!;

          return ListView.separated(
            // 2. APPLY DYNAMIC PADDING
            // Replaced const EdgeInsets.all(16) to include bottomPadding
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + bottomPadding, // <--- The Fix
            ),
            itemCount: feedbackList.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = feedbackList[index];
              final category = item['category'] ?? 'OTHER';
              final message = item['message'] ?? '';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: _getCategoryTextColor(category),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(message, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}