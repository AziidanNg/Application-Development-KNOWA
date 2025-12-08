// lib/screens/applicant_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/pending_user.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicantProfileScreen extends StatefulWidget {
  final PendingUser user;

  const ApplicantProfileScreen({super.key, required this.user});

  @override
  State<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState extends State<ApplicantProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // --- 1. NEW LOGIC TO UPDATE USER (Same as Manage Applications) ---
  void _updateUser(String action, {String? reason}) async {
    setState(() { _isLoading = true; });

    String finalAction = action;
    
    // Map the friendly action name to the API action name
    if (action == 'Approve') {
      finalAction = widget.user.profile.applicationType == 'MEMBERSHIP' 
          ? 'APPROVE_MEMBER' 
          : 'APPROVE_VOLUNTEER';
    } else if (action == 'Reject') {
      finalAction = 'REJECT';
    } else if (action == 'Interview') {
      finalAction = 'INTERVIEW';
    }

    // Call the API
    bool success = await _authService.updateUserStatus(
      widget.user.id, 
      finalAction, 
      reason: reason
    );

    setState(() { _isLoading = false; });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User updated successfully' : 'Failed to update user'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        Navigator.pop(context, true); // Go back and refresh list
      }
    }
  }

  // --- 2. NEW DIALOG FOR REJECTION ---
  void _showRejectDialog() {
    String selectedReason = 'Not suitable';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Application'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a reason for rejection:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Not suitable', child: Text('Not suitable for role')),
                      DropdownMenuItem(value: 'Underage', child: Text('Underage (<18)')),
                      DropdownMenuItem(value: 'Incomplete Documents', child: Text('Incomplete/Blurry Documents')),
                      DropdownMenuItem(value: 'Position Filled', child: Text('Position Filled')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _updateUser('Reject', reason: selectedReason); // Call update with reason
              },
              child: const Text('Reject & Notify'),
            ),
          ],
        );
      },
    );
  }

  void _launchFile(String? fileUrl) async {
    // 1. Debug Print: Check what URL is actually coming through
    print("Trying to open: $fileUrl"); 

    // 2. Check if empty (Give feedback like the donation screen does)
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('No document was uploaded.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final Uri url = Uri.parse(fileUrl);

    // 3. Use platformDefault exactly like your working screen
    if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Could not open file.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper to extract profile data
    final profile = widget.user.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Applicant Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    widget.user.firstName.isNotEmpty ? widget.user.firstName[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 32, color: Colors.blue.shade800),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.firstName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(widget.user.email, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          profile.applicationType == 'VOLUNTEER' ? 'Volunteer Applicant' : 'Membership Applicant',
                          style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- INFO SECTION ---
            const Text('Applicant Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Name', widget.user.firstName),
            _buildInfoRow('Email', widget.user.email),
            _buildInfoRow('Phone', widget.user.phone),
            
            // --- 3. SHOW IC NUMBER HERE ---
            _buildInfoRow('IC Number', profile.icNumber), 
            // -----------------------------
            
            const SizedBox(height: 32),
            const Text('Background', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Education', profile.education),
            _buildInfoRow('Occupation', profile.occupation),
            const SizedBox(height: 16),
            const Text('Reason for Joining:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text(profile.reasonForJoining, style: const TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 32),
            const Text('Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchFile(profile.resumeUrl),
                    icon: const Icon(Icons.description),
                    label: const Text('View Resume'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchFile(profile.identificationUrl),
                    icon: const Icon(Icons.badge),
                    label: const Text('View ID'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            
            // --- ACTION BUTTONS ---
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton('Approve', Colors.green, () => _updateUser('Approve')),
                
                // --- 4. CONNECT REJECT TO DIALOG ---
                _buildActionButton('Reject', Colors.red, _showRejectDialog),
                // ----------------------------------
                
                _buildActionButton('Interview', Colors.blue, () => _updateUser('Interview')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(label),
    );
  }
}