// lib/screens/admin_manage_applications_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/pending_user.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:knowa_frontend/screens/applicant_profile_screen.dart';

class AdminManageApplicationsScreen extends StatefulWidget {
  const AdminManageApplicationsScreen({super.key});

  @override
  State<AdminManageApplicationsScreen> createState() =>
      _AdminManageApplicationsScreenState();
}

class _AdminManageApplicationsScreenState extends State<AdminManageApplicationsScreen> {
  final AuthService _authService = AuthService();
  late Future<List<PendingUser>> _pendingUsersFuture;

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  void _loadPendingUsers() {
    setState(() {
      _pendingUsersFuture = _authService.getPendingUsers();
    });
  }

  void _updateUser(int userId, String action, String applicationType) async {
    String finalAction = action;

    // If the action is 'Approve', figure out which kind
    if (action == 'Approve') {
      finalAction = applicationType == 'MEMBERSHIP' 
          ? 'APPROVE_MEMBER' 
          : 'APPROVE_VOLUNTEER';
    }

    bool success = await _authService.updateUserStatus(userId, finalAction);

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User $action' 'ed successfully' : 'Failed to update user status'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
    _loadPendingUsers(); // Refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Applications'),
      ),
      body: FutureBuilder<List<PendingUser>>(
        future: _pendingUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending applications.'));
          }

          List<PendingUser> pendingUsers = snapshot.data!;

          return ListView.builder(
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final user = pendingUsers[index];
              final daysAgo = DateTime.now().difference(user.dateJoined).inDays;

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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(
                                user.profile.applicationType == 'MEMBERSHIP' 
                                  ? 'Applied for: Membership' 
                                  : 'Applied for: Volunteer',
                                style: const TextStyle(color: Colors.blue, fontSize: 12),
                              ),
                              Text('Applied $daysAgo days ago', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () async {
                              // --- UPDATE THIS ---
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  // Pass the full user object to the new screen
                                  builder: (context) => ApplicantProfileScreen(user: user),
                                ),
                              );

                              // If the detail screen returns 'true', it means
                              // an action was taken, so we should refresh this list.
                              if (result == true) {
                                _loadPendingUsers();
                              }
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(
                            text: 'Approve',
                            color: Colors.blue.shade700,
                            // --- UPDATE THIS ---
                            onPressed: () => _updateUser(user.id, 'Approve', user.profile.applicationType),
                          ),
                          _buildActionButton(
                            text: 'Reject',
                            color: Colors.red,
                            // --- UPDATE THIS ---
                            onPressed: () => _updateUser(user.id, 'Reject', user.profile.applicationType),
                          ),
                          _buildActionButton(
                            text: 'Interview',
                            color: Colors.white,
                            textColor: Colors.blue.shade700,
                            borderColor: Colors.blue.shade700,
                            // --- UPDATE THIS ---
                            onPressed: () => _updateUser(user.id, 'Interview', user.profile.applicationType),
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

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
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