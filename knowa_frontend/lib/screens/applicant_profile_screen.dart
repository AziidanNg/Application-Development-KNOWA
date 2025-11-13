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

  // This function handles all three button presses
  void _updateUser(String action) async {
    setState(() { _isLoading = true; });

    bool success = await _authService.updateUserStatus(widget.user.id, action.toUpperCase());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User $action' 'ed successfully' : 'Failed to update user status'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      // Pop back to the list screen, sending 'true' to signal a refresh
      Navigator.of(context).pop(true);
    }
  }

  // Function to launch the file URL in a browser
  void _launchFile(String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('No file was uploaded.'), backgroundColor: Colors.orange),
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


  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final profile = user.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicant Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Applicant Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', user.name),
            _buildInfoRow('Email', user.email),
            _buildInfoRow('Phone', user.phone),
            _buildInfoRow('Role', user.memberStatus), // This will say "PENDING"

            const SizedBox(height: 32),
            const Text(
              'Background',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Education', profile.education),
            _buildInfoRow('Occupation', profile.occupation),
            _buildInfoRow('Age', profile.age.toString()),
            _buildInfoRow('Reason for Joining', profile.reasonForJoining),

            const SizedBox(height: 32),
            const Text(
              'Attached Files',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFileRow('Resume', profile.resumeUrl),
            _buildFileRow('Identification', profile.idUrl),
          ],
        ),
      ),
      // --- Bottom Action Buttons ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(
              text: 'Approve',
              color: Colors.blue.shade700,
              onPressed: _isLoading ? null : () => _updateUser('Approve'),
            ),
            _buildActionButton(
              text: 'Reject',
              color: Colors.red,
              onPressed: _isLoading ? null : () => _updateUser('Reject'),
            ),
            _buildActionButton(
              text: 'Interview',
              color: Colors.white,
              textColor: Colors.blue.shade700,
              borderColor: Colors.blue.shade700,
              onPressed: _isLoading ? null : () => _updateUser('Interview'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for "Name", "Email", etc.
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
          const Divider(height: 12),
        ],
      ),
    );
  }

  // Helper for "resume.pdf", "ID.jpg"
  Widget _buildFileRow(String label, String? fileUrl) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      child: ListTile(
        leading: Icon(Icons.description_outlined, color: Colors.grey[700]),
        title: Text(
          fileUrl == null || fileUrl.isEmpty 
            ? 'No $label provided' 
            : fileUrl.split('/').last, // Show just the filename
          style: TextStyle(
            fontStyle: fileUrl == null ? FontStyle.italic : FontStyle.normal,
            color: fileUrl == null ? Colors.grey[600] : Colors.black
          ),
        ),
        trailing: fileUrl != null && fileUrl.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.remove_red_eye_outlined),
              onPressed: () => _launchFile(fileUrl),
            )
          : null,
      ),
    );
  }

  // Helper for the bottom buttons
  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback? onPressed,
    Color textColor = Colors.white,
    Color? borderColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: borderColor != null
                  ? BorderSide(color: borderColor)
                  : BorderSide.none,
            ),
          ),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}