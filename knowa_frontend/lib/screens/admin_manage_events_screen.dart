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
    _loadEvents(); // Load events
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = _eventService.getEvents();
    });
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
            icon: const Icon(Icons.add),
            onPressed: () async { // <-- Make this async
              // Open the "New Event" form and WAIT for a result
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const AdminCreateEventScreen(),
                  fullscreenDialog: true,
                ),
              );

              // If the page returns 'true', refresh the list
              if (result == true) {
                setState(() {
                  _eventsFuture = _eventService.getEvents();
                });
              }
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
          _buildEventList(_eventsFuture, 'PUBLISHED', isUpcoming: false), // Shows 'PUBLISHED' events from the past

          // "Drafts" Tab
          _buildEventList(_eventsFuture, 'DRAFT', isUpcoming: false),
        ],
      ),
    );
  }

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

        final allEvents = snapshot.data!;
        List<Event> filteredEvents;

        if (isUpcoming) {
          filteredEvents = allEvents.where((e) => e.status == 'PUBLISHED' && e.startTime.isAfter(DateTime.now())).toList();
        } else if (status == 'PUBLISHED') { // For the "Past" tab
          filteredEvents = allEvents.where((e) => e.status == 'PUBLISHED' && e.startTime.isBefore(DateTime.now())).toList();
        } else { // For the "Drafts" tab
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

  Widget _buildEventListItem(Event event) {
    final date = DateFormat('MMM d, yyyy').format(event.startTime);
    final time = DateFormat('h:mm a').format(event.startTime);
    final endTime = DateFormat('h:mm a').format(event.endTime);
    final location = event.isOnline ? 'Online' : event.location;

    return GestureDetector(
      onTap: () async {
        // This is your EDIT logic
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => AdminCreateEventScreen(eventToEdit: event),
            fullscreenDialog: true,
          ),
        );
        if (result == true) {
          _loadEvents();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // --- NEW: Event Image ---
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                event.imageUrl,
                width: 80, // Slightly smaller
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 40));
                },
              ),
            ),
            const SizedBox(width: 16),

            // --- Event Details ---
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

            // --- NEW: DELETE BUTTON ---
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                // This stops the tap from triggering the "edit" action
                (e) => e.stopPropagation(); 
                _confirmDelete(event); // Call the delete confirmation
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- ADD THIS NEW CONFIRMATION FUNCTION ---
  // This shows a pop-up to confirm deletion
  Future<void> _confirmDelete(Event event) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Event?'),
          content: Text('Are you sure you want to delete "${event.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Call the API to delete
                bool success = await _eventService.deleteEvent(event.id);

                if (!mounted) return;

                Navigator.of(dialogContext).pop(); // Close the dialog

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event deleted successfully'), backgroundColor: Colors.green),
                  );
                  _loadEvents(); // Refresh the list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete event'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}