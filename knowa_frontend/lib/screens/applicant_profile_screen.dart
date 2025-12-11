// lib/screens/applicant_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/models/pending_user.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ApplicantProfileScreen extends StatefulWidget {
  final PendingUser user;

  const ApplicantProfileScreen({super.key, required this.user});

  @override
  State<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState extends State<ApplicantProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _updateUser(String action, {String? reason, String? date, String? link, int? staffId}) async {
    setState(() { _isLoading = true; });

    String finalAction = action;
    
    if (action == 'Approve') {
      finalAction = widget.user.profile.applicationType == 'MEMBERSHIP' 
          ? 'APPROVE_MEMBER' 
          : 'APPROVE_VOLUNTEER';
    } else if (action == 'Reject') {
      finalAction = 'REJECT';
    } else if (action == 'Interview') {
      finalAction = 'INTERVIEW';
    }

    bool success = await _authService.updateUserStatus(
       widget.user.id, 
       finalAction, 
       reason: reason,
       date: date,
       link: link,
       staffId: staffId 
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
        Navigator.pop(context, true); 
      }
    }
  }

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
                Navigator.pop(context);
                _updateUser('Reject', reason: selectedReason);
              },
              child: const Text('Reject & Notify'),
            ),
          ],
        );
      },
    );
  }

  void _launchFile(String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('No document was uploaded.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final Uri url = Uri.parse(fileUrl);

    if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Could not open file.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- NEW: SEARCHABLE STAFF SELECTION DIALOG ---
  void _showStaffSelectionDialog(
      List<Map<String, dynamic>> staffList,
      Function(int? staffId) onStaffSelected,
      int? currentStaffId,
      Function(VoidCallback fn) setDialogState,
  ) {
    String searchText = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Interviewer'),
          content: StatefulBuilder(
            builder: (context, setInnerDialogState) {
              // Filter logic
              final filteredStaff = staffList.where((staff) {
                final name = staff['name'].toString().toLowerCase();
                return name.contains(searchText.toLowerCase());
              }).toList();
              
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Bar
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search Staff Name',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setInnerDialogState(() {
                          searchText = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // Staff List
                    Expanded(
                      child: filteredStaff.isEmpty 
                        ? const Center(child: Text("No staff found"))
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredStaff.length,
                          itemBuilder: (context, index) {
                            final staff = filteredStaff[index];
                            final isSelected = currentStaffId == staff['id'];
                            return ListTile(
                              title: Text(staff['name']),
                              tileColor: isSelected ? Colors.blue.shade50 : null,
                              trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                              onTap: () {
                                setDialogState(() {
                                  onStaffSelected(staff['id']);
                                });
                                Navigator.pop(context); // Close search dialog
                              },
                            );
                          },
                        ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // --- UPDATED: SCHEDULE DIALOG WITH SEARCH ---
  void _showScheduleDialog() async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String meetingLink = 'https://meet.google.com/abc-defg-hij';
    
    // Fetch Staff List
    List<Map<String, dynamic>> staffList = await _authService.getStaffList();
    int? selectedStaffId; 

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Schedule Interview'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              // Helper to get display name for the box
              String staffNameDisplay = selectedStaffId != null 
                  ? staffList.firstWhere((s) => s['id'] == selectedStaffId, orElse: () => {'name': 'Unknown'})['name']
                  : 'Select Staff *';

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select Date, Time & Interviewer:'),
                    const SizedBox(height: 16),
                    
                    // --- SEARCHABLE STAFF BUTTON (Replaces Dropdown) ---
                    InkWell(
                      onTap: () => _showStaffSelectionDialog(
                        staffList, 
                        (id) => selectedStaffId = id, 
                        selectedStaffId, 
                        setDialogState
                      ),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Assign Interviewer',
                          border: const OutlineInputBorder(),
                          errorText: selectedStaffId == null ? 'Please select an interviewer' : null,
                          prefixIcon: const Icon(Icons.person),
                        ),
                        child: Text(
                          staffNameDisplay,
                          style: TextStyle(
                            color: selectedStaffId == null ? Colors.grey : Colors.black,
                            fontWeight: selectedStaffId != null ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // --------------------------------------------------
                    const SizedBox(height: 16),

                    // Date Picker
                    ListTile(
                      title: Text("Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(), // Future Dates Only
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setDialogState(() => selectedDate = picked);
                      },
                    ),

                    // Time Picker
                    ListTile(
                      title: Text("Time: ${selectedTime.format(context)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          initialEntryMode: TimePickerEntryMode.dial,
                        );
                        if (picked != null) setDialogState(() => selectedTime = picked);
                      },
                    ),
                    
                    // Link Input
                    TextField(
                      decoration: const InputDecoration(labelText: 'Meeting Link'),
                      controller: TextEditingController(text: meetingLink),
                      onChanged: (val) => meetingLink = val,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Manual Validation for Staff Selection
                if (selectedStaffId == null) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an interviewer')));
                   return;
                }

                final finalDateTime = DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day,
                  selectedTime.hour, selectedTime.minute
                );
                
                Navigator.pop(context);
                
                _updateUser(
                  'Interview', 
                  date: finalDateTime.toIso8601String(), 
                  link: meetingLink,
                  staffId: selectedStaffId 
                );
              },
              child: const Text('Schedule'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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

            // Info Section
            const Text('Applicant Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Name', widget.user.firstName),
            _buildInfoRow('Email', widget.user.email),
            _buildInfoRow('Phone', widget.user.phone),
            _buildInfoRow('IC Number', profile.icNumber), 
            
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
            
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton('Approve', Colors.green, () => _updateUser('Approve')),
                
                _buildActionButton('Reject', Colors.red, _showRejectDialog),
                
                _buildActionButton('Interview', Colors.blue, _showScheduleDialog),
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