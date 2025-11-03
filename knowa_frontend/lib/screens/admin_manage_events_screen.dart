import 'package:flutter/material.dart';
import 'package:knowa_frontend/screens/admin_create_event_screen.dart';
import 'package:knowa_frontend/models/event.dart';
import 'package:knowa_frontend/services/event_service.dart';
import 'package:intl/intl.dart';

class AdminManageEventsScreen extends StatefulWidget {
  const AdminManageEventsScreen({super.key});

  @override
  State<AdminManageEventsScreen> createState() => _AdminManageEventsScreenState();
}

class _AdminManageEventsScreenState extends State<AdminManageEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventService _eventService = EventService();
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _eventsFuture = _eventService.getEvents(); // Load events
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
            icon: const Icon(Icons.add), // Changed to standard "+"
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminCreateEventScreen(),
                  fullscreenDialog: true,
                ),
              ).then((_) {
                // When "Create Event" screen closes, refresh the list
                setState(() {
                  _eventsFuture = _eventService.getEvents();
                });
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue.shade700,
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
          // "Upcoming" Tab
          _buildEventList(_eventsFuture, 'PUBLISHED', isUpcoming: true),
          
          // "Past" Tab
          _buildEventList(_eventsFuture, 'COMPLETED', isUpcoming: false),

          // "Drafts" Tab
          _buildEventList(_eventsFuture, 'DRAFT', isUpcoming: false),
        ],
      ),
    );
  }

  // This widget builds the list of events for each tab
  Widget _buildEventList(Future<List<Event>> future, String status, {bool isUpcoming = false}) {
    return FutureBuilder<List<Event>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No events found.'));
        }

        // Filter the events based on the tab's status
        final allEvents = snapshot.data!;
        List<Event> filteredEvents;
        
        if (isUpcoming) {
          // "Upcoming" = PUBLISHED and in the future
          filteredEvents = allEvents.where((e) => e.status == 'PUBLISHED' && e.startTime.isAfter(DateTime.now())).toList();
        } else if (status == 'COMPLETED') {
           // "Past" = PUBLISHED and in the past
          filteredEvents = allEvents.where((e) => e.status == 'PUBLISHED' && e.startTime.isBefore(DateTime.now())).toList();
        }
        else {
          // "Drafts" = DRAFT status
          filteredEvents = allEvents.where((e) => e.status == 'DRAFT').toList();
        }

        if (filteredEvents.isEmpty) {
          return const Center(child: Text('No events in this category.'));
        }

        return ListView.builder(
          itemCount: filteredEvents.length,
          itemBuilder: (context, index) {
            return _buildEventListItem(filteredEvents[index]);
          },
        );
      },
    );
  }

  // This is the list item from your screenshot
  Widget _buildEventListItem(Event event) {
    final date = DateFormat('MMM d, yyyy').format(event.startTime);
    final time = DateFormat('h:mm a').format(event.startTime);
    final endTime = DateFormat('h:mm a').format(event.endTime);
    final location = event.isOnline ? 'Online' : event.location;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$date · $time – $endTime',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  location,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.network(
              event.imageUrl,
              width: 100,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(width: 100, height: 80, color: Colors.grey[200], child: Icon(Icons.broken_image));
              },
            ),
          ),
        ],
      ),
    );
  }
}