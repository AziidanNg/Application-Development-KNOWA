import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Track the currently focused day and the selected day
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // --- MOCK DATA (We will replace this with Real Backend Data later) ---
  final Map<DateTime, List<Map<String, String>>> _events = {
    DateTime.utc(2025, 12, 5): [
      {'title': 'Leadership Skills Workshop', 'time': '10:00 AM - 12:00 PM', 'type': 'EVENT'}
    ],
    DateTime.utc(2025, 12, 12): [
      {'title': 'Interview with Admin', 'time': '2:00 PM - 2:30 PM', 'type': 'INTERVIEW'}
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // Helper to retrieve events for a specific day
  List<dynamic> _getEventsForDay(DateTime day) {
    // We normalize the date to UTC to match the map keys
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Personal Reminder feature coming soon!')),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. THE CALENDAR WIDGET
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            
            // Interaction
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            eventLoader: _getEventsForDay,

            // Styling to match your wireframe
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            calendarStyle: CalendarStyle(
              // The Blue Circle for Selected Day
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF1976D2), // Your App Blue
                shape: BoxShape.circle,
              ),
              // The "Today" highlight
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              // The little marker dots for events
              markerDecoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. SELECTED DATE TITLE
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              DateFormat('MMMM d, yyyy').format(_selectedDay!),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 10),

          // 3. EVENT LIST FOR THE DAY
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
      // Use your existing BottomNavBar logic here later
    );
  }

  // 4. THE EVENT CARD WIDGET
  Widget _buildEventCard(Map<String, String> event) {
    bool isInterview = event['type'] == 'INTERVIEW';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Date/Icon Box
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: isInterview ? Colors.orange[100] : Colors.blue[100], // Orange for Interview, Blue for Event
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isInterview ? Icons.video_call : Icons.calendar_today,
              color: isInterview ? Colors.orange[800] : Colors.blue[800],
            ),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  event['time']!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}