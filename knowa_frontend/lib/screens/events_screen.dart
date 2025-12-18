import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/services/event_service.dart';
import 'package:knowa_frontend/models/event.dart';
import 'package:knowa_frontend/screens/admin_manage_events_screen.dart'; // Redirects Admins here
import 'package:knowa_frontend/screens/event_detail_screen.dart';
import 'package:intl/intl.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final AuthService _authService = AuthService();
  final EventService _eventService = EventService();

  // State
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Online', 'Offline'

  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final user = await _authService.getUserData();
    setState(() {
      _userData = user;
      _isLoading = false;
      // Load events only if not admin (Admins get redirected anyway)
      if (user != null && user['is_staff'] != true) { 
        _eventsFuture = _eventService.getEvents();
      }
    });
  }

  // --- FILTER LOGIC ---
  List<Event> _filterEvents(List<Event> events) {
    return events.where((event) {
      // 1. Search Filter
      final matchesSearch = event.title.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // 2. Category Filter (Using Online/Offline status as categories)
      bool matchesCategory = true;
      if (_selectedFilter == 'Online') {
        matchesCategory = event.isOnline;
      } else if (_selectedFilter == 'Offline') {
        matchesCategory = !event.isOnline;
      }

      // 3. Only show Published/Upcoming events for public
      final isUpcoming = event.startTime.isAfter(DateTime.now());
      
      return matchesSearch && matchesCategory && isUpcoming;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- 1. ADMIN CHECK ---
    // If the user is an Admin, show the Management Screen instead
    if (_userData != null && _userData!['is_staff'] == true) {
      return const AdminManageEventsScreen();
    }

    // --- 2. PUBLIC / MEMBER UI ---
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Events', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.search, size: 28),
                    onPressed: () {
                      // Optional: Focus the search bar logic
                    },
                  ),
                ],
              ),
            ),

            // --- SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search events',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // --- FILTER CHIPS ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Online'), // Maps to Webinars/Virtual
                  const SizedBox(width: 8),
                  _buildFilterChip('Offline'), // Maps to Workshops/Community
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- EVENT LIST ---
            Expanded(
              child: FutureBuilder<List<Event>>(
                future: _eventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No upcoming events found.'));
                  }

                  final filteredList = _filterEvents(snapshot.data!);

                  if (filteredList.isEmpty) {
                    return const Center(child: Text('No events match your search.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return _buildEventCard(filteredList[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: Colors.blue.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }

  Widget _buildEventCard(Event event) {
    final dateStr = DateFormat('MMM d, yyyy').format(event.startTime);
    final timeStr = DateFormat('h:mm a').format(event.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Navigate to Details on click
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(
                  event: event,
                  userData: _userData!,
                ),
              ),
            );
            // Refresh list on return (in case they joined)
            setState(() {
              _eventsFuture = _eventService.getEvents();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$dateStr · $timeStr',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.isOnline ? 'Online' : event.location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      
                      // "Join" Button (Visual only - action is on Tap)
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () async {
                             // Same action as tapping the card
                             await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(
                                  event: event,
                                  userData: _userData!,
                                ),
                              ),
                            );
                            setState(() {
                              _eventsFuture = _eventService.getEvents();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Text('Join', style: TextStyle(color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),

                // Image Section
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    event.imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.event, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}