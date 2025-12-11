// lib/models/pending_user.dart

class PendingUser {
  final int id;
  final String firstName;
  final String email;
  final String phone;
  final String memberStatus;
  final DateTime dateJoined; // <--- 1. ADDED THIS FIELD
  final UserProfile profile;

  PendingUser({
    required this.id,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.memberStatus,
    required this.dateJoined, // <--- 2. ADDED TO CONSTRUCTOR
    required this.profile,
  });

  factory PendingUser.fromJson(Map<String, dynamic> json) {
    return PendingUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? 'N/A',
      memberStatus: json['member_status'] ?? 'PENDING',
      // 3. PARSE THE DATE (Default to now if missing)
      dateJoined: json['application_date'] != null 
          ? DateTime.parse(json['application_date']) 
          : DateTime.now(), // Fallback to now if null
      profile: UserProfile.fromJson(json['profile'] ?? {}),
    );
  }
}

class UserProfile {
  final String applicationType;
  final String education;
  final String occupation;
  final String reasonForJoining;
  final String resumeUrl;
  final String identificationUrl;
  final String icNumber;
  final String paymentReceiptUrl;

  UserProfile({
    required this.applicationType,
    required this.education,
    required this.occupation,
    required this.reasonForJoining,
    required this.resumeUrl,
    required this.identificationUrl,
    required this.icNumber,
    required this.paymentReceiptUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      applicationType: json['application_type'] ?? 'MEMBERSHIP',
      education: json['education'] ?? '',
      occupation: json['occupation'] ?? '',
      reasonForJoining: json['reason_for_joining'] ?? '',
      resumeUrl: json['resume'] ?? '',
      identificationUrl: json['identification'] ?? '',
      icNumber: json['ic_number'] ?? 'N/A',
      paymentReceiptUrl: json['payment_receipt'] ?? '',
    );
  }
}