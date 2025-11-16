import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // No 'const'
      appBar: AppBar(title: const Text('Chat')),
      body: const Center(child: Text('Admin Chat Screen - Coming Soon!', style: TextStyle(fontSize: 20))),
    );
  }
}