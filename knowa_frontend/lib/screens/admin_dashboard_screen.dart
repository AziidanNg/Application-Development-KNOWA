// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/login_screen.dart';
import 'package:knowa_frontend/screens/admin_manage_applications_screen.dart';
import 'package:knowa_frontend/screens/admin_pending_payments_screen.dart';
import 'package:knowa_frontend/screens/admin_pending_donations_screen.dart';
import 'package:knowa_frontend/screens/admin_manage_events_screen.dart';
import 'package:knowa_frontend/models/admin_stats.dart'; 
import 'package:knowa_frontend/screens/notification_screen.dart'; // <--- 1. IMPORT THIS
import 'package:intl/intl.dart'; 

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  final AuthService _authService = AuthService();
  late Future<AdminStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _authService.getAdminStats();
  }

  void _handleLogout(BuildContext context) async {
    await _authService.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_MY', symbol: 'RM');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // --- 2. ADD NOTIFICATION BUTTON HERE ---
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
          // ---------------------------------------
          
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _handleLogout(context),
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

            FutureBuilder<AdminStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading stats: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No stats found.'));
                }

                final stats = snapshot.data!;

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      'Total Members', 
                      stats.totalMembers.toString(), 
                      '+10%', 
                      Colors.green
                    ),
                    _buildStatCard(
                      'Pending Applications', 
                      stats.pendingApplications.toString(), 
                      '-5%', 
                      Colors.red
                    ),
                    _buildStatCard(
                      'Active Events', 
                      stats.activeEvents.toString(), 
                      '+20%', 
                      Colors.green
                    ),
                    _buildStatCard(
                      'Monthly Donations', 
                      currencyFormatter.format(stats.monthlyDonations), 
                      '+15%', 
                      Colors.green
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              title: 'Member Applications',
              onPressed: () { 
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminManageApplicationsScreen(),
                  ),
                );
              },
              isPrimary: true,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              title: 'Pending Payments',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPendingPaymentsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              title: 'Pending Donations',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPendingDonationsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              title: 'Create Event',
              onPressed: () { 
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminManageEventsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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