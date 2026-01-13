class AdminStats {
  final int totalMembers;
  final int pendingApplications;
  final int activeEvents;
  final double monthlyDonations;
  final Map<String, int> userComposition; // <--- New Field

  AdminStats({
    required this.totalMembers,
    required this.pendingApplications,
    required this.activeEvents,
    required this.monthlyDonations,
    required this.userComposition,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalMembers: json['total_members'] ?? 0,
      pendingApplications: json['pending_applications'] ?? 0,
      activeEvents: json['active_events'] ?? 0,
      monthlyDonations: (json['monthly_donations'] as num?)?.toDouble() ?? 0.0,
      // Parse the new map safely
      userComposition: Map<String, int>.from(json['user_composition'] ?? {}),
    );
  }
}