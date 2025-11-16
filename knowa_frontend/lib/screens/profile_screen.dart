// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/login_screen.dart';
import 'package:knowa_frontend/screens/membership_application_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Future<Map<String, dynamic>>? _userFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fetch user data from storage
  void _loadData() {
    setState(() {
      _userFuture = _authService.getUserData();
    });
  }

  // This logs the user out
  void _handleLogout(BuildContext context) async {
    await _authService.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // This converts the database status (e.g., "PENDING")
  // into a user-friendly string (e.g., "Pending")
  String _getFriendlyStatus(String dbStatus) {
    switch (dbStatus) {
      case 'PUBLIC':
        return 'Public User';
      case 'PENDING':
        return 'Pending Application';
      case 'INTERVIEW':
        return 'Interview Pending';
      case 'APPROVED_UNPAID':
        return 'Pending Payment';
      case 'VOLUNTEER':
        return 'Volunteer';
      case 'MEMBER':
        return 'NGO Member';
      case 'REJECTED':
        return 'Application Rejected';
      default:
        return 'Active User';
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
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              // TODO: Navigate to Settings & Security screen
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load profile.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No profile data found.'));
          }

          final userData = snapshot.data!;
          final String displayName = userData['first_name'] ?? 'User';
          final String email = userData['username'] ?? 'No email';
          final String status = userData['member_status'] ?? 'PUBLIC';

          // This logic controls the "Apply" button
          final bool canApply = status == 'PUBLIC' || status == 'REJECTED';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Profile Header
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

                // --- THIS IS THE FIX ---
                // Account Section
                _buildSectionHeader('Account'),
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: userData['phone'] ?? 'N/A', // We'll add this to auth_service later
                ),
                _buildInfoRow(
                  icon: Icons.shield_outlined,
                  label: 'Status',
                  value: _getFriendlyStatus(status), // Shows the real status
                ),

                // "Apply Here" Button
                if (canApply)
                  _buildApplyCard(),

                // --- END OF FIX ---

                const SizedBox(height: 32),
                _buildSectionHeader('Settings'),
                _buildInfoRow(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  value: '',
                  onTap: () {},
                ),
                _buildInfoRow(
                  icon: Icons.lock_outline,
                  label: 'Privacy',
                  value: '',
                  onTap: () {},
                ),

                const SizedBox(height: 32),
                // Logout Button
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
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper for "Account" and "Settings" titles
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper for info rows
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Helper for the "Join Our Team" card
  Widget _buildApplyCard() {
    return Card(
      elevation: 0,
      color: Colors.blue[50],
      child: ListTile(
        title: const Text('Join Our Team', style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: ElevatedButton(
          onPressed: () async {
            // Navigate to the application form
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MembershipApplicationScreen()),
            );
            // If they submitted, reload the profile to show "Pending"
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