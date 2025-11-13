// lib/screens/admin_pending_payments_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/pending_user.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/applicant_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPendingPaymentsScreen extends StatefulWidget {
  const AdminPendingPaymentsScreen({super.key});

  @override
  State<AdminPendingPaymentsScreen> createState() =>
      _AdminPendingPaymentsScreenState();
}

// lib/screens/admin_pending_payments_screen.dart

class _AdminPendingPaymentsScreenState extends State<AdminPendingPaymentsScreen> {
  final AuthService _authService = AuthService();
  late Future<List<PendingUser>> _pendingPaymentsFuture;

  @override
  void initState() {
    super.initState();
    _loadPendingPayments();
  }

  void _loadPendingPayments() {
    setState(() {
      _pendingPaymentsFuture = _authService.getPendingPayments();
    });
  }

  // --- NEW: Function to launch the receipt file ---
  void _launchFile(String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('No receipt was uploaded.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final Uri url = Uri.parse(fileUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Could not open file.'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmPayment(int userId) async {
    bool success = await _authService.confirmPayment(userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Payment confirmed! User is now a member.' : 'Failed to confirm payment.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
    _loadPendingPayments(); // Refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Payments'),
      ),
      body: FutureBuilder<List<PendingUser>>(
        future: _pendingPaymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No payments to confirm.'));
          }

          List<PendingUser> pendingUsers = snapshot.data!;

          // --- THIS IS THE NEW, SIMPLER LIST ---
          return ListView.builder(
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final user = pendingUsers[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. "View Receipt" Button
                      IconButton(
                        icon: const Icon(Icons.receipt_long, color: Colors.blue),
                        onPressed: () {
                          _launchFile(user.profile.paymentReceiptUrl);
                        },
                        tooltip: 'View Receipt',
                      ),
                      // 2. "Confirm" Button
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () {
                          _confirmPayment(user.id);
                        },
                        tooltip: 'Confirm Payment',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          // --- END OF NEW LIST ---
        },
      ),
    );
  }
}