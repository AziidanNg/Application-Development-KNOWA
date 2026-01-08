import 'package:flutter/material.dart';
import 'package:knowa_frontend/screens/badges_screen.dart';

class BadgePreviewCard extends StatelessWidget {
  final List<dynamic> earnedBadges;
  final int totalEvents;
  final int totalDonations;

  const BadgePreviewCard({
    Key? key,
    required this.earnedBadges,
    required this.totalEvents,
    required this.totalDonations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine how many to show (max 5 to fit on screen)
    int displayCount = earnedBadges.length > 5 ? 4 : earnedBadges.length;
    int remaining = earnedBadges.length - displayCount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to full details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BadgesScreen(
                badges: earnedBadges,
                eventCount: totalEvents,
                donationCount: totalDonations,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Badges",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Badges Row (Images Only)
              earnedBadges.isEmpty
                  ? _buildEmptyState()
                  : Row(
                      children: [
                        ...List.generate(displayCount, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: _buildBadgeImage(earnedBadges[index]),
                          );
                        }),
                        
                        // If there are more than 5, show a "+2" circle
                        if (remaining > 0)
                          Container(
                            width: 45,
                            height: 45,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              "+$remaining",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build the circular image
  Widget _buildBadgeImage(dynamic badge) {
    // 1. Get the icon name from the backend (e.g. "calendar_month")
    String? iconName = badge['icon'];
    String? imageUrl = badge['image_url']; 
    
    // 2. Map the text name to a real Flutter Icon
    IconData iconData;
    switch (iconName) {
      case 'calendar_month': 
        iconData = Icons.calendar_month; 
        break;
      case 'volunteer_activism': 
        iconData = Icons.volunteer_activism; 
        break;
      // Add more cases here if you create more badges later
      case 'star':
      default: 
        iconData = Icons.star; // Only use Star if we don't know the name
    }

    // Determine color based on type (Optional)
    // If you don't have 'criteria_type', default to Orange
    Color badgeColor = Colors.orange;

    return Container(
      width: 48, 
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        // Logic: Try Image URL first, then try the Icon based on the switch case above
        child: imageUrl != null
            ? Image.network(
                imageUrl, 
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Icon(iconData, color: badgeColor, size: 24),
              )
            : Icon(iconData, color: badgeColor, size: 24),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.military_tech_outlined, color: Colors.grey[300], size: 30),
          const SizedBox(width: 10),
          Text(
            "No badges earned yet",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
}