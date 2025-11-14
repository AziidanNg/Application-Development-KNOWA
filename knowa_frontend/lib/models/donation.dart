// lib/models/donation.dart
import 'package:flutter/foundation.dart';

class Donation {
  final int id;
  final String username;
  final double amount;
  final String? receiptUrl;
  final String status;
  final DateTime submittedAt;

  Donation({
    required this.id,
    required this.username,
    required this.amount,
    this.receiptUrl,
    required this.status,
    required this.submittedAt,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {

    return Donation(
      id: json['id'],
      username: json['username'] ?? 'Unknown User',
      amount: double.parse(json['amount']),
      receiptUrl: json['receipt_url'],
      status: json['status'],
      submittedAt: DateTime.parse(json['submitted_at']),
    );
  }
}