// lib/screens/settings_sub_screens.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/local_notification_service.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// 1. MAIN SETTINGS SCREEN
// ==========================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsGroup([
            _buildSettingsTile(
              icon: Icons.language,
              title: "Language",
              subtitle: "English (US)",
              onTap: () {},
            ),
            const Divider(height: 1, indent: 60),
            _buildSettingsTile(
              icon: Icons.dark_mode_outlined,
              title: "Dark Mode",
              trailing: Switch(
                value: false, 
                activeColor: Colors.blue,
                onChanged: (val) {}
              ),
            ),
          ]),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text("ABOUT", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          _buildSettingsGroup([
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: "About Knowa",
              subtitle: "Version 1.0.0 (Beta)",
              onTap: () {},
            ),
            const Divider(height: 1, indent: 60),
            _buildSettingsTile(
              icon: Icons.article_outlined,
              title: "Terms of Service",
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue.shade700, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}

// ==========================================
// 2. NOTIFICATION SETTINGS (WITH LOGIC)
// ==========================================
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final AuthService _authService = AuthService();
  
  bool _emailNotifs = true;
  bool _eventReminders = false;
  int _reminderHoursBefore = 1; 

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailNotifs = prefs.getBool('email_notifs') ?? true;
      _eventReminders = prefs.getBool('event_reminders') ?? false;
      _reminderHoursBefore = prefs.getInt('reminder_hours') ?? 1;
    });
  }

  // --- SYNC LOGIC (Connects to Backend & Local Notifications) ---
  Future<void> _syncReminders() async {
    await LocalNotificationService.cancelAll(); // Clear old to prevent dupes

    if (!_eventReminders) return;

    try {
      final schedule = await _authService.getMySchedule(); // Fetch from Backend
      
      int scheduledCount = 0;
      final offset = Duration(hours: _reminderHoursBefore);

      for (var item in schedule) {
        final String startTimeStr = item['start'] ?? item['date_time']; 
        final DateTime eventTime = DateTime.parse(startTimeStr);
        final String title = item['title'] ?? 'Upcoming Activity';
        final int id = item['id']; 

        await LocalNotificationService.scheduleEventReminder(
          id: id,
          title: "Reminder: $title",
          body: "Starting in $_reminderHoursBefore hour(s)!",
          eventTime: eventTime,
          offset: offset,
        );
        scheduledCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Synced! $scheduledCount reminders scheduled."),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error syncing reminders: $e");
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: Colors.blue,
                  secondary: const Icon(Icons.email_outlined),
                  title: const Text("Email Notifications"),
                  subtitle: const Text("Weekly digests & updates"),
                  value: _emailNotifs,
                  onChanged: (val) {
                    setState(() => _emailNotifs = val);
                    _savePreference('email_notifs', val);
                  },
                ),
                
                const Divider(height: 1, indent: 60),
                
                // --- LOGIC-POWERED TOGGLE ---
                SwitchListTile(
                  activeColor: Colors.blue,
                  secondary: const Icon(Icons.event_available_outlined),
                  title: const Text("Event Reminders"),
                  subtitle: const Text("Notify me before joined events"),
                  value: _eventReminders,
                  onChanged: (val) {
                    setState(() => _eventReminders = val);
                    _savePreference('event_reminders', val);
                    _syncReminders(); // Run Logic
                  },
                ),

                // --- LOGIC-POWERED DROPDOWN ---
                if (_eventReminders) ...[
                  const Divider(height: 1, indent: 60),
                  ListTile(
                    title: const Text("Remind me:", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    trailing: DropdownButton<int>(
                      value: _reminderHoursBefore,
                      underline: const SizedBox(),
                      style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 15),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("1 Hour Before")),
                        DropdownMenuItem(value: 12, child: Text("12 Hours Before")),
                        DropdownMenuItem(value: 24, child: Text("1 Day Before")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _reminderHoursBefore = val);
                          _savePreference('reminder_hours', val);
                          _syncReminders(); // Run Logic
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "Note: Reminders update automatically based on your schedule.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 3. PRIVACY & SECURITY SCREEN (PROFESSIONAL DESIGN)
// ==========================================
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Privacy & Security", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECURITY BANNER ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 40, color: Colors.green.shade700),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Your data is secure", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                        SizedBox(height: 4),
                        Text("We use end-to-end encryption for your personal details.", style: TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- DATA SECTION ---
            _buildSectionHeader("Data We Collect"),
            _buildInfoCard([
              _buildBulletPoint("Profile Information (Name, Email, Phone)"),
              _buildBulletPoint("Donation History & Receipts"),
              _buildBulletPoint("Event Attendance Records"),
            ]),

            const SizedBox(height: 24),

            // --- USAGE SECTION ---
            _buildSectionHeader("How We Use It"),
            _buildInfoCard([
              _buildBulletPoint("To verify NGO membership status."),
              _buildBulletPoint("To process donation tax exemptions."),
              _buildBulletPoint("We NEVER sell your data to third parties."),
            ]),

            const SizedBox(height: 32),

            // --- DANGER ZONE ---
            _buildSectionHeader("Account Control"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.delete_forever, color: Colors.red.shade700),
                ),
                title: const Text("Delete Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                subtitle: const Text("Permanently remove all data"),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text("Delete Account?"),
                      content: const Text("This action cannot be undone. All your data will be wiped."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                        TextButton(
                          onPressed: () => Navigator.pop(c), 
                          child: const Text("Delete", style: TextStyle(color: Colors.red))
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}