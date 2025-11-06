// lib/screens/event_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/event.dart';
import 'package:knowa_frontend/services/event_service.dart'; // Import the service
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// --- 1. CONVERT TO STATEFULWIDGET ---
class EventDetailScreen extends StatefulWidget {
  final Event event;
  final Map<String, dynamic> userData; 

  const EventDetailScreen({super.key, required this.event, required this.userData});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  // --- 2. ADD STATE VARIABLES ---
  final EventService _eventService = EventService();
  bool _isLoading = false;

  // This is a local, changeable copy of the event
  late Event _currentEvent;
  late bool _isMember;
  late String _buttonText;

  @override
  void initState() {
    super.initState();
    // Initialize our local state with the data passed to the screen
    _currentEvent = widget.event;
    _isMember = widget.userData['member_status'] == 'MEMBER' || widget.userData['is_staff'] == true;
    _buttonText = _isMember ? 'Join as Crew' : 'Register Now';
  }

  // --- 3. THIS IS THE COMPLETE BUTTON LOGIC ---
  void _handleRegisterOrJoin() async {
    setState(() { _isLoading = true; });
    
    // Call the API
    final result = await _eventService.joinEvent(_currentEvent.id, asCrew: _isMember);

    if (!mounted) return; // Check if the widget is still in the tree
    
    if (result['success']) {
      // --- IT WORKED! NOW RE-FETCH THE EVENT DATA ---
      try {
        final updatedEvent = await _eventService.getEventDetails(_currentEvent.id);
        setState(() {
          _currentEvent = updatedEvent; // Update the UI with new counts
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['data']['status'] ?? 'Successfully registered!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Failed to re-fetch, but still show success
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully registered! (Could not refresh counts)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // It failed (e.g., "Capacity full")
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 4. READ FROM THE LOCAL _currentEvent, NOT widget.event ---
    final String formattedDate = DateFormat('E, MMM d, yyyy • h:mm a').format(_currentEvent.startTime);
    final String formattedEndTime = DateFormat('h:mm a').format(_currentEvent.endTime);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          // --- 5. FIX NAVIGATOR.POP TO PASS BACK 'TRUE' ---
          onPressed: () => Navigator.of(context).pop(true), // Send 'true' to refresh dashboard
        ),
        title: const Text('Event Details', style: TextStyle(color: Colors.black)),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              _currentEvent.imageUrl,
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
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentEvent.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('$formattedDate – $formattedEndTime', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  
                  InkWell(
                    onTap: () async {
                      final query = Uri.encodeComponent(_currentEvent.location);
                      final url = Uri.parse('http://googleusercontent.com/maps.google.com/search/?api=1&query=$query');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
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
                              _currentEvent.location,
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
                  const SizedBox(height: 8),
                  
                  // These numbers will now update instantly
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_currentEvent.participantCount} / ${_currentEvent.capacityParticipants} Participant Spots Filled',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currentEvent.crewCount} / ${_currentEvent.capacityCrew} Crew Spots Filled',
                        style: TextStyle(fontSize: 16, color: Colors.blue[700], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegisterOrJoin, // Wired up
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _buttonText, // Use the state variable
                            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        final String shareText = 
                          "Join me at this event!\n\n"
                          "${_currentEvent.title}\n"
                          "When: $formattedDate\n"
                          "Where: ${_currentEvent.location}";
                        Share.share(shareText);
                      },
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
                  
                  const Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(
                    _currentEvent.description,
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