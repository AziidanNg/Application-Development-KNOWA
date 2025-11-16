// lib/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/screens/dashboard_screen.dart'; // Public Dashboard
import 'package:knowa_frontend/screens/admin_dashboard_screen.dart'; // Admin Dashboard
import 'package:knowa_frontend/screens/events_screen.dart';
import 'package:knowa_frontend/screens/calendar_screen.dart';
import 'package:knowa_frontend/screens/chatbot_screen.dart';
import 'package:knowa_frontend/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  // --- 1. ADD THIS ---
  // We will pass the user's data to this screen
  final Map<String, dynamic> userData;

  const MainNavigationScreen({super.key, required this.userData});
  // -----------------

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0; 

  // --- 2. MAKE THE SCREEN LIST DYNAMIC ---
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // --- 3. BUILD THE SCREEN LIST BASED ON ROLE ---
    // Get the user's role from the "widget" (passed from the login screen)
    final bool isStaff = widget.userData['is_staff'] ?? false;

    _screens = <Widget>[
      // --- THIS IS THE FIX ---
      // If the user is staff, show AdminDashboard, otherwise show public Dashboard
      isStaff ? const AdminDashboardScreen() : const DashboardScreen(),
      // -----------------------

      const EventsScreen(),
      const CalendarScreen(),
      const ChatbotScreen(),
      const ProfileScreen(),
    ];
    // ---------------------------------
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens.elementAt(_selectedIndex), // Show the selected screen
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 10.0,
      ),
    );
  }
}