import 'package:flutter/material.dart';
import 'package:knowa_frontend/screens/admin_create_event_screen.dart';
// We will use these in a moment
// import 'package:knowa_frontend/models/event.dart';
// import 'package:knowa_frontend/services/event_service.dart';

class AdminManageEventsScreen extends StatefulWidget {
  const AdminManageEventsScreen({super.key});

  @override
  State<AdminManageEventsScreen> createState() => _AdminManageEventsScreenState();
}

class _AdminManageEventsScreenState extends State<AdminManageEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // Open the "New Event" form as a pop-up
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminCreateEventScreen(),
                  fullscreenDialog: true, // This makes it slide up
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Drafts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TODO: Build the "Upcoming" events list here
          const Center(child: Text('Upcoming Events List (TODO)')),
          
          // TODO: Build the "Past" events list here
          const Center(child: Text('Past Events List (TODO)')),

          // TODO: Build the "Drafts" events list here
          const Center(child: Text('Drafts List (TODO)')),
        ],
      ),
    );
  }
}