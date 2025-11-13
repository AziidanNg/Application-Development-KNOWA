// lib/models/pending_user.dart

// This class matches the 'profile' data from your backend
class UserProfile {
  final String education;
  final String occupation;
  final String reasonForJoining;
  final int age;
  final String? resumeUrl;
  final String? idUrl;

  UserProfile({
    required this.education,
    required this.occupation,
    required this.reasonForJoining,
    required this.age,
    this.resumeUrl,
    this.idUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      education: json['education'] ?? '',
      occupation: json['occupation'] ?? '',
      reasonForJoining: json['reason_for_joining'] ?? '',
      age: json['age'] ?? 0,
      resumeUrl: json['resume'],
      idUrl: json['identification'],
    );
  }
}

// This is the main class for the applicant
class PendingUser {
  final int id;
  final String name; // This is the 'first_name' field
  final String email;
  final String phone;
  final String memberStatus;
  final DateTime dateJoined;
  final UserProfile profile; // The nested profile data

  PendingUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.memberStatus,
    required this.dateJoined,
    required this.profile,
  });

  factory PendingUser.fromJson(Map<String, dynamic> json) {
    return PendingUser(
      id: json['id'],
      name: json['first_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      memberStatus: json['member_status'],
      dateJoined: DateTime.parse(json['date_joined']),
      profile: UserProfile.fromJson(json['profile'] ?? {}),
    );
  }
}