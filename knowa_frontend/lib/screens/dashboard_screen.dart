// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/event.dart';
import 'package:knowa_frontend/services/event_service.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/login_screen.dart';
import 'package:knowa_frontend/screens/event_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EventService _eventService = EventService();
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the events when the screen loads
    _eventsFuture = _eventService.getEvents();
  }

  void _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();

    // Go back to Login Screen and remove all other screens from history
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false, // This clears the stack
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Home', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _handleLogout(context), // Call the logout function
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Hi, User" text
            const Text(
              'Hi, User 👋',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // "Upcoming Events" Section
            const Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildEventList(),

            // We will build these other sections in later sprints
            const SizedBox(height: 24),
            const Text(
              'Donation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // ... Donation UI ...
            const SizedBox(height: 24),
            const Text(
              'Announcements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // ... Announcements UI ...
          ],
        ),
      ),
      // We will build the main navigation bar in a later step
    );
  }

  // This widget builds the horizontal list of events
  Widget _buildEventList() {
    return FutureBuilder<List<Event>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        // 1. While loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } 
        // 2. If there's an error
        else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } 
        // 3. If there's no data
        else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No upcoming events.'));
        }

        // 4. We have data! Build the horizontal list
        List<Event> events = snapshot.data!;
        return Container(
          height: 230, // Fixed height for the horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _buildEventCard(context, events[index]);
            },
          ),
        );
      },
    );
  }

  // This widget is the "Upcoming Events" card from your design
  Widget _buildEventCard(BuildContext context, Event event) {
    // Format the date (e.g., "Nov 9, 2025")
    final String formattedDate = DateFormat('MMM d, yyyy').format(event.startTime);

    return GestureDetector(
      onTap: () {
         //Navigate to EventDetailScreen
         Navigator.of(context).push(
           MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
         );
      },
      child: Container(
        width: 250, // Fixed width for each card
        margin: const EdgeInsets.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                event.imageUrl,
                height: 150,
                width: 250,
                fit: BoxFit.cover,
                // Handle loading
                loadingBuilder: (context, child, progress) {
                  return progress == null 
                      ? child 
                      : Container(height: 150, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                },
                // Handle broken images
                errorBuilder: (context, error, stackTrace) {
                  return Container(height: 150, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey, size: 40));
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              formattedDate, // Use our formatted date
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}