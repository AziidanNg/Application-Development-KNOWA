// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

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
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        //Logout
        actions: [
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
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 2x2 Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard('Total Members', '1,250', '+10%', Colors.green),
                _buildStatCard('Pending Applications', '15', '-5%', Colors.red),
                _buildStatCard('Active Events', '8', '+20%', Colors.green),
                _buildStatCard('Monthly Donations', '\$5,500', '+15%', Colors.green),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              title: 'Member Applications',
              onPressed: () { /* TODO: Navigate to applications */ },
              isPrimary: true,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              title: 'Create Event',
              onPressed: () { /* TODO: Navigate to create event */ },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              title: 'Create Announcement',
              onPressed: () { /* TODO: Navigate to create announcement */ },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              title: 'Schedule Meeting',
              onPressed: () { /* TODO: Navigate to schedule meeting */ },
            ),
          ],
        ),
      ),
      // TODO: We will build the new Admin Bottom Nav Bar later
    );
  }

  // Helper widget for the stat cards
  Widget _buildStatCard(String title, String value, String change, Color changeColor) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(change, style: TextStyle(color: changeColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Helper widget for the action buttons
  Widget _buildActionButton({required String title, required VoidCallback onPressed, bool isPrimary = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.blue.shade700 : Colors.grey[200],
          foregroundColor: isPrimary ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}