// lib/screens/admin_pending_donations_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/donation.dart';
import 'package:knowa_frontend/services/donation_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPendingDonationsScreen extends StatefulWidget {
  const AdminPendingDonationsScreen({super.key});

  @override
  State<AdminPendingDonationsScreen> createState() => _AdminPendingDonationsScreenState();
}

class _AdminPendingDonationsScreenState extends State<AdminPendingDonationsScreen> {
  final DonationService _donationService = DonationService();
  late Future<List<Donation>> _pendingDonationsFuture;

  @override
  void initState() {
    super.initState();
    _loadPendingDonations();
  }

  void _loadPendingDonations() {
    setState(() {
      _pendingDonationsFuture = _donationService.getPendingDonations();
    });
  }

  // Function to launch the receipt file URL
  void _launchFile(String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('No receipt was uploaded.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final Uri url = Uri.parse(fileUrl);

    // --- THIS IS THE FIX ---
    if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
    // -----------------------
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Could not open file.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Function to handle the admin action
  // Function to handle the admin action
  void _handleDonation(int donationId, String action, {String? reason}) async {
    bool success = false;
    String successMessage = '';

    if (action == 'Approve') {
      success = await _donationService.approveDonation(donationId);
      successMessage = 'Receipt acknowledged successfully.';
    } else {
      // We are "Notifying Issue" (Rejecting)
      success = await _donationService.rejectDonation(donationId, reason: reason); 
      successMessage = 'Issue notified to donor: $reason';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? successMessage : 'Failed to update donation.'),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
    _loadPendingDonations(); 
  }

  void _showNotifyIssueDialog(int donationId) {
    String selectedReason = 'Blurry Receipt'; // Default reason
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notify Issue to Donor'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select the issue with this donation:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    isExpanded: true, // --- FIX: prevents overflow by fitting to width ---
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Blurry Receipt', 
                        // Added TextOverflow.ellipsis as a safety measure
                        child: Text('Receipt is blurry/unreadable', overflow: TextOverflow.ellipsis)
                      ),
                      DropdownMenuItem(value: 'Amount Mismatch', child: Text('Amount does not match receipt')),
                      DropdownMenuItem(value: 'Duplicate', child: Text('Duplicate submission')),
                      DropdownMenuItem(value: 'Invalid Date', child: Text('Receipt date is invalid')),
                      DropdownMenuItem(value: 'Other', child: Text('Other (See email)')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Call the reject function WITH the reason
                _handleDonation(donationId, 'Reject', reason: selectedReason); 
              },
              child: const Text('Notify User'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Donations'),
      ),
      body: FutureBuilder<List<Donation>>(
        future: _pendingDonationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending donations to review.'));
          }

          List<Donation> pendingDonations = snapshot.data!;

          return ListView.builder(
            itemCount: pendingDonations.length,
            itemBuilder: (context, index) {
              final donation = pendingDonations[index];
              final formattedDate = DateFormat('MMM d, yyyy').format(donation.submittedAt);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          // --- FIX START: Use Expanded to prevent overflow ---
                          Expanded( 
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  donation.username, 
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 1, // Limit to 1 line
                                  overflow: TextOverflow.ellipsis, // Add '...' if too long
                                ),
                                Text('Submitted $formattedDate', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8), // Small gap
                          Text(
                            'RM${donation.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // "View Receipt" Button
                      TextButton.icon(
                        icon: const Icon(Icons.receipt_long, color: Colors.blue),
                        label: const Text('View Receipt', style: TextStyle(color: Colors.blue)),
                        onPressed: () => _launchFile(donation.receiptUrl),
                      ),
                      const Divider(),
                      // Admin Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(
                            text: 'Acknowledge Receipt',
                            color: Colors.green.shade700,
                            onPressed: () => _handleDonation(donation.id, 'Approve'),
                          ),
                          _buildActionButton(
                            text: 'Notify Issue',
                            color: Colors.orange,
                            onPressed: () => _showNotifyIssueDialog(donation.id),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper widget for Approve/Reject buttons
  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}