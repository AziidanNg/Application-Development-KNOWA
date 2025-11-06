// lib/screens/event_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/event.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:url_launcher/url_launcher.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  final Map<String, dynamic> userData;

  const EventDetailScreen({super.key, required this.event, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Format the date (e.g., "Sat, Nov 9, 2025 • 10:00 AM – 12:00 PM")
    final String formattedDate = DateFormat('E, MMM d, yyyy • h:mm a').format(event.startTime);
    final String formattedEndTime = DateFormat('h:mm a').format(event.endTime);

    // --- 2. CHECK THE USER'S ROLE ---
    final bool isMember = userData['member_status'] == 'MEMBER' || userData['is_staff'] == true;
    final String buttonText = isMember ? 'Join as Crew' : 'Register Now';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Event Details', style: TextStyle(color: Colors.black)),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Event Image
            Image.network(
              event.imageUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 60),
                );
              },
            ),

            // 2. Main Content Area
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Date and Time
                  Text(
                    '$formattedDate – $formattedEndTime',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),

                  // Location
                  // --- NEW: Clickable Location Link ---
                  InkWell(
                    onTap: () async {
                      // This formats the location for a Google Maps URL
                      final query = Uri.encodeComponent(event.location);
                      final url = Uri.parse('http://maps.google.com/?q=$query');

                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open map.')),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                fontSize: 16, 
                                color: Colors.blue.shade700, 
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // --- END OF

                  // Spots Filled (Dummy data for now)
                  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${event.participantCount} / ${event.capacityParticipants} Participant Spots Filled',
                            style: TextStyle(
                              fontSize: 16, 
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${event.crewCount} / ${event.capacityCrew} Crew Spots Filled',
                            style: TextStyle(
                              fontSize: 16, 
                              color: Colors.blue[700], // Make crew spots stand out
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 24),

                  // Register Now Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () { /* TODO: Add Register/Join Crew Logic */ },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        buttonText, // <-- IT'S DYNAMIC NOW
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Share Event Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () { /* TODO: Add Share Logic */ },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[800],
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Share Event',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // About Section
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}