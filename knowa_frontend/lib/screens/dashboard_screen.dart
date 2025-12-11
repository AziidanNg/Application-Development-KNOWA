// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/event.dart';
import 'package:knowa_frontend/services/event_service.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/login_screen.dart';
import 'package:knowa_frontend/screens/event_detail_screen.dart';
import 'package:knowa_frontend/screens/membership_application_screen.dart';
import 'package:intl/intl.dart';
import 'package:knowa_frontend/screens/payment_screen.dart';
import 'package:knowa_frontend/services/donation_service.dart';
import 'package:knowa_frontend/screens/donation_page.dart';
import 'package:knowa_frontend/screens/fix_donation_screen.dart';
import 'package:knowa_frontend/screens/notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  final DonationService _donationService = DonationService();

  // This will hold our user data
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _donationIssue; // Holds the rejection reason if any

  // This will hold the events
  Future<List<Event>>? _eventsFuture;

  late Future<Map<String, dynamic>> _donationGoalFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
    _donationGoalFuture = _donationService.getDonationGoal();
    _checkDonationIssues();
  }

  // This function gets the user data first, then loads the events
  void _loadData() async {
    final userData = await _authService.getUserData();
    setState(() {
      _userData = userData;
      _eventsFuture = _eventService.getEvents();
    });
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

  // --- UPDATED: Simulating a check for donation issues ---
  void _checkDonationIssues() async {
    // Call the real API
    final issue = await _donationService.getLatestIssue();
    
    if (mounted) {
      setState(() {
        // If issue is null, this clears the alert. 
        // If issue exists, this shows the alert.
        _donationIssue = issue; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Home', style: TextStyle(color: Colors.black)),
        automaticallyImplyLeading: false, // Prevents back button to login
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting
            Text(
              'Hi, ${_userData?['first_name'] ?? 'User'} 👋',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // "Upcoming Events" Section
            const Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildEventList(),
            
            // --- Donation Section ---
            const SizedBox(height: 24),
            const Text(
              'Donation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _donationGoalFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final goalData = snapshot.data!;
                  return _buildDonationCard(goalData);
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),

            const SizedBox(height: 24),

            // --- NEW: DONATION ISSUE ALERT ---
            // This only shows up if there is an issue found
            if (_donationIssue != null) 
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50], // Light red background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 30),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Action Required: Donation Issue',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Admin Note: "${_donationIssue!['reason']}"',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                        onPressed: () async {
                          // 1. Get the data from the alert
                          int id = _donationIssue!['id'];
                          String reason = _donationIssue!['reason'];

                          // 2. Navigate to Fix Screen
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FixDonationScreen(donationId: id, reason: reason),
                            ),
                          );

                          // 3. If fixed successfully (result == true), refresh dashboard
                          if (result == true) {
                            setState(() {
                              _donationIssue = null; // Remove the alert immediately
                            });
                            // Optionally reload other data
                            // _loadData(); 
                          }
                        },
                      )
                    ],
                  ),
                ),
              ),
            // ---------------------------------

            // --- Announcements Section ---
            const Text(
              'Announcements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // This widget checks the user's status and shows the correct card
            _buildApplicationStatusWidget(),
            const SizedBox(height: 12),
            _buildAnnouncementCard(
              title: 'KNOWA EduTalks',
              text: 'Big dreams start with small stories. Don\'t miss KNOWA EduTalks this December',
            ),

            // --- My Activities Section ---
            const SizedBox(height: 24),
            const Text(
              'My Activities',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActivityCard(
              title: 'Events Joined',
              value: '12', 
            ),
          ],
        ),
      ),
    );
  }

  // ... (Keep all your existing helper widgets: _buildEventList, _buildEventCard, _buildDonationCard, _buildAnnouncementCard, _buildActivityCard, _buildApplicationStatusWidget, _buildPaymentCard, _buildStatusCard) ...
  // Paste them here unchanged.

  Widget _buildEventList() {
    // If the user data or events haven't loaded, show a spinner
    if (_eventsFuture == null || _userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Event>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No upcoming events.'));
        }

        List<Event> events = snapshot.data!;

        return Container(
          height: 230, // Set a fixed height for the horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _buildEventCard(context, events[index], _userData!);
            },
          ),
        );
      },
    );
  }

  Widget _buildEventCard(BuildContext context, Event event, Map<String, dynamic> userData) {
    final String formattedDate = DateFormat('MMM d, yyyy').format(event.startTime);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => EventDetailScreen(event: event, userData: userData)),
        );
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                event.imageUrl,
                height: 150,
                width: 250,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  return progress == null ? child : Container(height: 150, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(height: 150, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey, size: 40));
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> goalData) {
    final double goal = (goalData['goal'] as num).toDouble();
    final double current = (goalData['current_total'] as num).toDouble();
    final double progress = (goal > 0) ? (current / goal) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Goal: RM${goal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(current.toStringAsFixed(0), style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress, 
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DonationPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Donate', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard({required String title, required String text}) {
    bool isJoinCard = title == 'Join KNOWA';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isJoinCard ? () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MembershipApplicationScreen()),
          );
        } : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(text, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({required String title, required String value}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 150, 
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationStatusWidget() {
    if (_userData == null) {
      return const SizedBox(height: 60); 
    }

    final String status = _userData?['member_status'] ?? 'PUBLIC';

    switch (status) {
      case 'APPROVED_UNPAID':
        bool hasReceipt = _userData?['has_receipt'] ?? false;
        if (hasReceipt) {
          return _buildStatusCard(
            title: 'Payment Verification Pending',
            text: 'We have received your receipt. An admin will verify it shortly.',
            icon: Icons.receipt_long,
            color: Colors.blue,
          );
        } else {
          return _buildPaymentCard(); 
        }

      case 'PUBLIC':
        return InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MembershipApplicationScreen()),
            );
            if (result == true) {
              _loadData(); 
            }
          },
          child: _buildAnnouncementCard(
            title: 'Join KNOWA',
            text: 'Be Part of the Movement for Knowledge Empowerment!',
          ),
        );

      case 'PENDING':
        return _buildStatusCard(
          title: 'Application Pending',
          text: 'Your application is currently under review by our team.',
          icon: Icons.hourglass_top_outlined,
          color: Colors.orange,
        );

      case 'INTERVIEW':
        return _buildStatusCard(
          title: 'Interview',
          text: 'The admin team has requested an interview. Please check your email.',
          icon: Icons.record_voice_over_outlined,
          color: Colors.blue,
        );

      case 'REJECTED':
        String reason = _userData?['rejection_reason'] ?? '';
        if (reason.isEmpty) reason = 'Your application was not approved at this time.';

        return _buildStatusCard(
          title: 'Application Status: Rejected',
          text: reason, // <-- SHOW THE REAL REASON HERE
          icon: Icons.highlight_off, // Changed icon to look more like an alert
          color: Colors.red,
        );

      case 'MEMBER':
        return _buildStatusCard(
          title: 'Welcome, NGO Member!',
          text: 'You now have full access to member features.',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        );

      case 'VOLUNTEER':
        return _buildStatusCard(
          title: 'Welcome, Volunteer!',
          text: 'You are now registered as a project-based volunteer.',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPaymentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade700, width: 2)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! Your application is approved.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
            ),
            const SizedBox(height: 8),
            const Text('Please pay the one-time membership fee to become a full member.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PaymentScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Pay Membership Fee', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({required String title, required String text, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(text, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}