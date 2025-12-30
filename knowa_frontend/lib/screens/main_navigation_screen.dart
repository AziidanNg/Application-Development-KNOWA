// lib/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/screens/dashboard_screen.dart';
import 'package:knowa_frontend/screens/admin_dashboard_screen.dart';
import 'package:knowa_frontend/screens/events_screen.dart';
import 'package:knowa_frontend/screens/calendar_screen.dart';
import 'package:knowa_frontend/screens/profile_screen.dart';
import 'package:knowa_frontend/screens/chat_list_screen.dart'; // <--- IMPORT YOUR CHAT LIST

class MainNavigationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MainNavigationScreen({super.key, required this.userData});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  late bool _isAdmin;

  @override
  void initState() {
    super.initState();
    
    // Check if user is staff/admin based on the data passed from Login
    _isAdmin = widget.userData['is_staff'] == true;

    _screens = [
      // 1. Home (Dashboard)
      // If Admin, show AdminDashboard, else show User Dashboard
      _isAdmin ? const AdminDashboardScreen() : const DashboardScreen(),

      // 2. Events
      const EventsScreen(),

      // 3. Calendar
      const CalendarScreen(),

      // 4. CHAT (Replaces the old Chatbot tab)
      // This shows the list of Group Chats & DMs
      const ChatListScreen(), 

      // 5. Profile
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We use IndexedStack to keep the state of each tab alive
      // (so you don't lose your scroll position in Chat when you go to Profile)
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed, // Needed for 4+ items
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: 'Home'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number), 
            label: 'Events'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), 
            label: 'Calendar'
          ),
          // --- UPDATED TAB ---
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble), // Changed icon to generic Chat
            label: 'Chat'                  // Changed label from 'Chatbot'
          ),
          // -------------------
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'Profile'
          ),
        ],
      ),
    );
  }
}