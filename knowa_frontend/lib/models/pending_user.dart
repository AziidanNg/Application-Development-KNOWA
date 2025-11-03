// lib/models/pending_user.dart

class PendingUser {
  final int id;
  final String username;
  final String email;
  final String memberStatus;
  final DateTime dateJoined;

  PendingUser({
    required this.id,
    required this.username,
    required this.email,
    required this.memberStatus,
    required this.dateJoined,
  });

  // This factory constructor builds a PendingUser from the JSON
  factory PendingUser.fromJson(Map<String, dynamic> json) {
    return PendingUser(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      memberStatus: json['member_status'],
      dateJoined: DateTime.parse(json['date_joined']),
    );
  }
}