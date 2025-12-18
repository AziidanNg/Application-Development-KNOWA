// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/admin_create_meeting_screen.dart';
// --- 1. NEW IMPORTS ---
import 'package:url_launcher/url_launcher.dart'; 
import 'package:knowa_frontend/screens/event_detail_screen.dart'; 
import 'package:knowa_frontend/services/event_service.dart'; 

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final AuthService _authService = AuthService();
  
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  bool _isAdmin = false;

  Map<DateTime, List<dynamic>> _events = {}; 

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    _checkAdminStatus();
    _loadSchedule(); 
  }

  void _checkAdminStatus() async {
    final userData = await _authService.getUserData();
    if (userData != null) {
      setState(() {
        _isAdmin = userData['is_staff'] ?? false;
      });
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _loadSchedule() async {
    final scheduleData = await _authService.getMySchedule();
    Map<DateTime, List<dynamic>> newEvents = {};

    for (var item in scheduleData) {
      try {
        DateTime rawDate = DateTime.parse(item['date']);
        DateTime dateKey = DateTime.utc(rawDate.year, rawDate.month, rawDate.day);

        if (newEvents[dateKey] == null) {
          newEvents[dateKey] = [];
        }
        newEvents[dateKey]!.add(item);
      } catch (e) {
        print("Error parsing date: $e");
      }
    }

    if (mounted) {
      setState(() {
        _events = newEvents;
        _isLoading = false;
        if (_selectedDay != null) {
          _selectedEvents.value = _getEventsForDay(_selectedDay!);
        }
      });
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _pickMonthYear() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime.utc(2020, 1, 1),
      lastDate: DateTime.utc(2030, 12, 31),
      initialDatePickerMode: DatePickerMode.year, 
      helpText: 'Select Month & Year',
    );

    if (picked != null && picked != _focusedDay) {
      setState(() {
        _focusedDay = picked; 
        _selectedDay = picked; 
        _selectedEvents.value = _getEventsForDay(picked);
      });
    }
  }

  // --- 2. NEW: Handle Item Taps (Event vs Meeting) ---
  void _handleItemTap(Map<String, dynamic> item) async {
    String type = item['type'];
    int id = item['id'];

    if (type == 'EVENT') {
      // Fetch full event details and open screen
      setState(() { _isLoading = true; });
      try {
        final eventService = EventService();
        final eventObj = await eventService.getEventDetails(id);
        final userData = await _authService.getUserData();
        
        if (userData != null && mounted) { 
          setState(() { _isLoading = false; });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: eventObj, userData: userData),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() { _isLoading = false; });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not load event details")));
        }
      }
    } else {
      // Show Bottom Sheet for Meetings/Interviews
      _showSimpleDetailSheet(item);
    }
  }

  // --- 3. NEW: Bottom Sheet for Meetings ---
  void _showSimpleDetailSheet(Map<String, dynamic> item) {
    String title = item['title'] ?? 'No Title';
    String description = item['description'] ?? 'No Description';
    String link = item['meeting_link'] ?? '';
    String location = item['location'] ?? '';
    String time = item['time'] ?? '';
    bool isMeeting = item['type'] == 'MEETING';
    
    // Only show admin actions if it's a meeting AND user is admin
    bool showAdminActions = _isAdmin && isMeeting; 

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Icon(
                    isMeeting ? Icons.groups : Icons.video_call,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  
                  // --- NEW: EDIT & DELETE BUTTONS ---
                  if (showAdminActions) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () async {
                        Navigator.pop(context); // Close sheet first
                        final result = await Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => AdminCreateMeetingScreen(meetingToEdit: item))
                        );
                        if (result == true) {
                          setState(() { _isLoading = true; });
                          _loadSchedule();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        Navigator.pop(context); // Close sheet
                        // Confirm Delete
                        bool confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Meeting'),
                            content: const Text('Are you sure you want to delete this meeting?'),
                            actions: [
                              TextButton(onPressed: ()=>Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: ()=>Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          )
                        ) ?? false;

                        if (confirm) {
                          final service = EventService();
                          await service.deleteMeeting(item['id']);
                          setState(() { _isLoading = true; });
                          _loadSchedule();
                        }
                      },
                    ),
                  ]
                  // ----------------------------------
                ],
              ),
              // ... rest of the UI (Time, Location, Description) remains the same ...
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(time, style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              if (link.isNotEmpty) 
                InkWell(
                  onTap: () async {
                    final Uri url = Uri.parse(link);
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.link, size: 20, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          link, 
                          style: const TextStyle(fontSize: 16, color: Colors.blue, decoration: TextDecoration.underline),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else if (location.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(location, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              const SizedBox(height: 24),
              const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description, style: TextStyle(color: Colors.grey[800], height: 1.4)),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() { _isLoading = true; });
              _loadSchedule();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      floatingActionButton: _isAdmin 
        ? FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminCreateMeetingScreen()),
              );
              if (result == true) {
                setState(() { _isLoading = true; });
                _loadSchedule();
              }
            },
            label: const Text('New Meeting'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.blue.shade700,
          )
        : null,
      body: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                ),
                InkWell(
                  onTap: _pickMonthYear,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_focusedDay),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Calendar Grid
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            headerVisible: false, 
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF1976D2),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Selected Date Title
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _selectedDay != null 
                  ? DateFormat('MMMM d, yyyy').format(_selectedDay!)
                  : 'Select a date',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          
          // Event List
          Expanded(
            child: ValueListenableBuilder<List<dynamic>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return Center(
                    child: Text('No events for this day.', style: TextStyle(color: Colors.grey[500])),
                  );
                }
                return ListView.builder(
                  itemCount: value.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return _buildEventCard(event);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. UPDATED: Event Card with InkWell and Tap Logic ---
  Widget _buildEventCard(Map<String, dynamic> event) {
    String type = event['type'] ?? 'EVENT'; 
    String title = event['title'] ?? 'No Title';
    String time = event['time'] ?? 'All Day';
    String location = event['location'] ?? '';

    Color bgColor;
    Color iconColor;
    IconData iconData;

    if (type == 'INTERVIEW') {
      bgColor = Colors.orange.shade100;
      iconColor = Colors.orange.shade800;
      iconData = Icons.video_call; 
    } else if (type == 'MEETING') {
      bgColor = Colors.purple.shade100;
      iconColor = Colors.purple.shade800;
      iconData = Icons.groups; 
    } else {
      bgColor = Colors.blue.shade100;
      iconColor = Colors.blue.shade800;
      iconData = Icons.calendar_today;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleItemTap(event), // <--- TAP HANDLER
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: bgColor, 
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          if (location.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                location, 
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
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