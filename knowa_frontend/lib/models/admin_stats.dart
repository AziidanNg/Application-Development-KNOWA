// lib/models/admin_stats.dart

class AdminStats {
  final int totalMembers;
  final int pendingApplications;
  final int activeEvents;
  final double monthlyDonations;

  AdminStats({
    required this.totalMembers,
    required this.pendingApplications,
    required this.activeEvents,
    required this.monthlyDonations,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalMembers: json['total_members'] ?? 0,
      pendingApplications: json['pending_applications'] ?? 0,
      activeEvents: json['active_events'] ?? 0,
      monthlyDonations: (json['monthly_donations'] as num).toDouble(),
    );
  }
}