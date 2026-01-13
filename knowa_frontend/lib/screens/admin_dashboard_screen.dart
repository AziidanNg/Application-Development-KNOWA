// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/login_screen.dart';
import 'package:knowa_frontend/screens/admin_manage_applications_screen.dart';
import 'package:knowa_frontend/screens/admin_pending_payments_screen.dart';
import 'package:knowa_frontend/screens/admin_pending_donations_screen.dart';
import 'package:knowa_frontend/models/admin_stats.dart'; 
import 'package:knowa_frontend/screens/notification_screen.dart';
import 'package:intl/intl.dart'; 
import 'package:knowa_frontend/main.dart';
import 'package:knowa_frontend/screens/admin_interview_history_screen.dart';
import 'package:fl_chart/fl_chart.dart';

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
        MaterialPageRoute(
          builder: (context) => const AppRootWrapper(child: LoginScreen()), 
        ),
        (Route<dynamic> route) => false, 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_MY', symbol: 'RM');
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 16.0 + bottomPadding,
        ),
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. STATISTICS CARDS ---
                    GridView.count(
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
                          'Pending Apps', 
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
                    ),

                    const SizedBox(height: 32),

                    // --- 2. USER COMPOSITION CHART (UPDATED) ---
                    const Text(
                      "User Composition", 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 16),
                    Container(
                      // REMOVED FIXED HEIGHT so it grows dynamically
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05), 
                            blurRadius: 10, 
                            offset: const Offset(0, 4)
                          )
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: stats.userComposition.isEmpty 
                          ? const Center(child: Text("No user data available"))
                          : _buildCompositionChart(stats.userComposition),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            
            // --- 3. QUICK ACTIONS ---
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
              title: 'View Interview Reports',
              onPressed: () { 
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminInterviewHistoryScreen(),
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

  // --- HELPER FOR PIE CHART (UPDATED LAYOUT) ---
  Widget _buildCompositionChart(Map<String, int> data) {
    // Define colors for specific keys
    final Map<String, Color> categoryColors = {
      'Public Users': Colors.blue.shade300,
      'NGO Members': Colors.green,
      'Pending': Colors.orange,
      'Staff': Colors.purple,
    };

    List<PieChartSectionData> sections = [];
    data.forEach((key, value) {
      if (value > 0) {
        sections.add(
          PieChartSectionData(
            color: categoryColors[key] ?? Colors.grey,
            value: value.toDouble(),
            title: '$value',
            radius: 45, // Slightly smaller radius to look neat
            titleStyle: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold, 
              color: Colors.white
            ),
          ),
        );
      }
    });

    // Use Column to stack Chart ON TOP of Legend
    return Column(
      children: [
        // 1. THE PIE CHART (Top)
        SizedBox(
          height: 180, // Dedicated height for just the chart circle
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        
        const SizedBox(height: 24), // Space between chart and legend

        // 2. THE LEGEND (Bottom, Wrapped)
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,     // Horizontal space
          runSpacing: 12,  // Vertical space
          children: data.entries.map((entry) {
            if (entry.value == 0) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Container(
                  width: 12, height: 12, 
                  decoration: BoxDecoration(
                    color: categoryColors[entry.key] ?? Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${entry.key} (${entry.value})",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}