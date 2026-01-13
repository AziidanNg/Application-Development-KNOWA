class AdminStats {
  final int totalMembers;
  final String memberGrowth; // New

  final int pendingApplications;
  final String pendingGrowth; // New

  final int activeEvents;
  final String eventGrowth; // New

  final double monthlyDonations;
  final String donationGrowth; // New

  final Map<String, int> userComposition;

  AdminStats({
    required this.totalMembers,
    required this.memberGrowth,
    required this.pendingApplications,
    required this.pendingGrowth,
    required this.activeEvents,
    required this.eventGrowth,
    required this.monthlyDonations,
    required this.donationGrowth,
    required this.userComposition,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalMembers: json['total_members'] ?? 0,
      memberGrowth: json['member_growth'] ?? "0%", // Default if missing
      
      pendingApplications: json['pending_applications'] ?? 0,
      pendingGrowth: json['pending_growth'] ?? "0%",

      activeEvents: json['active_events'] ?? 0,
      eventGrowth: json['event_growth'] ?? "0%",

      monthlyDonations: (json['monthly_donations'] as num?)?.toDouble() ?? 0.0,
      donationGrowth: json['donation_growth'] ?? "0%",

      userComposition: Map<String, int>.from(json['user_composition'] ?? {}),
    );
  }
}