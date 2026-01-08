import 'package:flutter/material.dart';

class BadgesScreen extends StatelessWidget {
  final List<dynamic> badges;
  final int eventCount;
  final int donationCount;

  const BadgesScreen({
    Key? key, 
    required this.badges,
    required this.eventCount, 
    required this.donationCount
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Achievements", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Stats Header
            _buildStatsCard(),
            const SizedBox(height: 24),

            // 2. Badges Grid
            const Text("Your Collection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            badges.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: badges.length,
                    itemBuilder: (context, index) {
                      return _buildBadgeCard(badges[index]);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Events", eventCount.toString(), Icons.event),
          Container(width: 1, height: 40, color: Colors.blue.shade200),
          _buildStatItem("Donations", donationCount.toString(), Icons.volunteer_activism),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBadgeCard(dynamic badge) {
    String type = badge['criteria_type'] ?? 'EVENT';
    Color color = type == 'EVENT' ? Colors.orange : Colors.purple;
    String? imageUrl = badge['image_url'];

    return Column(
      children: [
        Container(
          height: 80, width: 80,
          padding: const EdgeInsets.all(4), // Thin padding
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3)),
            ],
          ),
          child: imageUrl != null
              ? ClipOval(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              : Icon(Icons.star, color: color, size: 40),
        ),
        const SizedBox(height: 8),
        Text(
          badge['name'],
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text("No badges yet!", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}