import 'package:flutter/material.dart';
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Events')),
      body: Center(child: Text('Events Screen - Coming Soon!', style: TextStyle(fontSize: 20))),
    );
  }
}