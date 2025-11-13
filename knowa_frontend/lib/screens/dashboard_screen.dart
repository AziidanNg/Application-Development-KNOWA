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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();

  // This will hold our user data
  Map<String, dynamic>? _userData;

  // This will hold the events
  Future<List<Event>>? _eventsFuture;

  // We've moved the user loading to its own function
  @override
  void initState() {
    super.initState();
    _loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Home', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black),
            onPressed: () {},
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
            // This now reads the state variable, which is much safer
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
                
                // --- ADD ALL THIS NEW CODE ---

                // --- 1. Donation Section ---
                const SizedBox(height: 24),
                const Text(
                  'Donation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDonationCard(), // Call the new helper widget

                // --- 2. Announcements Section ---
                const SizedBox(height: 24),
                const Text(
                  'Announcements',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // This new widget checks the user's status and shows the correct card
                _buildApplicationStatusWidget(),
                const SizedBox(height: 12),
                _buildAnnouncementCard(
                  title: 'KNOWA EduTalks',
                  text: 'Big dreams start with small stories. Don\'t miss KNOWA EduTalks this December',
                ),

                // --- 3. My Activities Section ---
                const SizedBox(height: 24),
                const Text(
                  'My Activities',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildActivityCard(
                  title: 'Events Joined',
                  value: '12', // This is a placeholder
                ),
                
                // --- END OF NEW CODE ---
              ],
            ),
          ),
      // TODO: Add the Bottom Navigation Bar here
    );
  }

  // This widget builds the list of events
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

  // This widget is the card from your design
  Widget _buildEventCard(BuildContext context, Event event, Map<String, dynamic> userData) {
    final String formattedDate = DateFormat('MMM d, yyyy').format(event.startTime);

    return GestureDetector(
      onTap: () {
        // Pass the user data to the detail screen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => EventDetailScreen(event: event, userData: userData)),
        );
      },
      child: Container(
        width: 250, // Fixed width for each card
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
                // Handle image loading/error
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

  Widget _buildDonationCard() {
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
                const Text('Goal: RM10,000', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('6000', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            // This is the progress bar
            LinearProgressIndicator(
              value: 0.6, // 6000 / 10000 = 0.6
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () { /* TODO: Navigate to Donation Page */ },
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

  // --- WIDGET FOR ANNOUNCEMENT CARD ---
  Widget _buildAnnouncementCard({required String title, required String text}) {
    // --- NEW: Check if this is the "Join" card ---
    bool isJoinCard = title == 'Join KNOWA';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell( // --- NEW: Wrap with InkWell ---
        onTap: isJoinCard ? () {
          // --- NEW: Navigation logic ---
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MembershipApplicationScreen()),
          );
        } : null, // Disable tap for other cards
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
            // Placeholder for the "Join KNOWA" button
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

  // --- WIDGET FOR ACTIVITY CARD ---
  Widget _buildActivityCard({required String title, required String value}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 150, // Fixed width
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

  // This function checks the user's status and shows the correct card
Widget _buildApplicationStatusWidget() {
  // If user data hasn't loaded yet, show an empty box
  if (_userData == null) {
    return const SizedBox(height: 60); 
  }

  // Get the user's status
  final String status = _userData?['member_status'] ?? 'PUBLIC';

  switch (status) {
    case 'APPROVED_UNPAID':
      return _buildPaymentCard(); // Show the "Pay Fee" card

    case 'PUBLIC':
      // 1. If they are public, show the "Join KNOWA" button
      return _buildAnnouncementCard(
        title: 'Join KNOWA',
        text: 'Be Part of the Movement for Knowledge Empowerment!',
      );

    case 'PENDING':
      // 2. If they are pending, show a "Pending" status card
      return _buildStatusCard(
        title: 'Application Pending',
        text: 'Your application is currently under review by our team.',
        icon: Icons.hourglass_top_outlined,
        color: Colors.orange,
      );

    case 'INTERVIEW':
      // 3. If they are set for interview, show an "Interview" card
      return _buildStatusCard(
        title: 'Interview',
        text: 'The admin team has requested an interview. Please check your email.',
        icon: Icons.record_voice_over_outlined,
        color: Colors.blue,
      );

    case 'REJECTED':
      // 4. If they were rejected, show a "Rejected" card
      return _buildStatusCard(
        title: 'Application Status',
        text: 'Your application was not approved at this time.',
        icon: Icons.close,
        color: Colors.red,
      );

    case 'MEMBER':
      // 5. If they are a full member, show nothing.
      return const SizedBox.shrink(); // Hides the card

    default:
      return const SizedBox.shrink();
  }
}

// --- ADD THIS HELPER for the new "Pay Fee" card ---
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

// --- ADD THIS HELPER for the new status cards ---
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