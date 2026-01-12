// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/login_screen.dart';
import 'package:knowa_frontend/screens/membership_application_screen.dart';
import 'package:knowa_frontend/main.dart'; 
import 'package:knowa_frontend/screens/admin_feedback_screen.dart';
// --- IMPORT THE NEW SETTINGS SCREENS ---
import 'package:knowa_frontend/screens/settings_sub_screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Future<Map<String, dynamic>?>? _userFuture; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _userFuture = _authService.getUserData();
    });
  }

  void _handleLogout(BuildContext context) async {
    await _authService.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AppRootWrapper(child: LoginScreen()),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  // --- IMPROVED FEEDBACK DIALOG (WIDTH & HEIGHT FIXED) ---
  void _showFeedbackDialog() {
    final TextEditingController _messageController = TextEditingController();
    String _selectedCategory = 'IMPROVEMENT';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Send Feedback'),
              content: SizedBox(
                width: double.maxFinite, // Fix width
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Help us improve the app!'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'BUG', child: Text('Bug Report')),
                          DropdownMenuItem(value: 'FEATURE', child: Text('Feature Request')),
                          DropdownMenuItem(value: 'IMPROVEMENT', child: Text('Improvement')),
                          DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setDialogState(() => _selectedCategory = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _messageController,
                        minLines: 4, // Fix height
                        maxLines: 4, 
                        decoration: const InputDecoration(
                          labelText: 'Your Message',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          hintText: 'Tell us what you think...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_messageController.text.trim().isEmpty) return;
                    Navigator.pop(context); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sending feedback...')),
                    );
                    bool success = await _authService.submitFeedback(
                      _selectedCategory,
                      _messageController.text,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Thank you! Feedback sent.' : 'Failed to send feedback.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                  ),
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getFriendlyStatus(String dbStatus) {
    switch (dbStatus) {
      case 'PUBLIC': return 'Public User';
      case 'PENDING': return 'Pending Application';
      case 'INTERVIEW': return 'Interview Pending';
      case 'APPROVED_UNPAID': return 'Pending Payment';
      case 'VOLUNTEER': return 'Volunteer';
      case 'MEMBER': return 'NGO Member';
      case 'REJECTED': return 'Application Rejected';
      default: return 'Active User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // --- 1. SETTINGS BUTTON (Top Right) ---
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>( 
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load profile.'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No profile data found.'));
          }

          final userData = snapshot.data!;
          final String displayName = userData['first_name'] ?? 'User';
          final String email = userData['username'] ?? 'No email';
          final String status = userData['member_status'] ?? 'PUBLIC';
          final bool canApply = status == 'PUBLIC' || status == 'REJECTED';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  email,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // --- Account Section ---
                _buildSectionHeader('Account'),
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: userData['phone'] ?? 'N/A',
                ),
                _buildInfoRow(
                  icon: Icons.shield_outlined,
                  label: 'Status',
                  value: _getFriendlyStatus(status),
                ),

                if (canApply) _buildApplyCard(),

                const SizedBox(height: 32),
                
                // --- Support Section ---
                _buildSectionHeader('Support'),
                
                _buildInfoRow(
                  icon: Icons.feedback_outlined,
                  label: 'Send Feedback',
                  value: '',
                  onTap: _showFeedbackDialog,
                ),

                if (userData['is_staff'] == true) ...[
                  const SizedBox(height: 8), 
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: _buildInfoRow(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: Colors.blueGrey.shade700,
                      label: 'View User Feedback',
                      value: 'Admin',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminFeedbackScreen()),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // --- Settings Section ---
                _buildSectionHeader('Settings'),
                
                // --- 2. NOTIFICATIONS BUTTON ---
                _buildInfoRow(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  value: '',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                    );
                  },
                ),
                
                // --- 3. PRIVACY BUTTON ---
                _buildInfoRow(
                  icon: Icons.lock_outline,
                  label: 'Privacy',
                  value: '',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                    );
                  },
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => _handleLogout(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align( 
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey[700]),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty) 
            Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          if (onTap != null) ...[
             if (value.isNotEmpty) const SizedBox(width: 8),
             const Icon(Icons.arrow_forward_ios, size: 16),
          ]
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), 
    );
  }

  Widget _buildApplyCard() {
    return Card(
      elevation: 0,
      color: Colors.blue[50],
      child: ListTile(
        title: const Text('Join Our Team', style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MembershipApplicationScreen()),
            );
            if (result == true) {
              _loadData();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Apply Here', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}