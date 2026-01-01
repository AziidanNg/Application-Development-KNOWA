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
  bool _isLoading = false; // Added loading state for dialog actions

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

  // --- UPDATED UPDATE LOGIC (Handles Interview Data) ---
  void _updateUser(int userId, String action, String applicationType, {String? reason, String? date, String? link, int? staffId}) async {
    setState(() { _isLoading = true; });

    String finalAction = action;
    
    // Map the simple action to the backend status enum
    if (action == 'Approve') {
      finalAction = applicationType == 'MEMBERSHIP' 
          ? 'APPROVE_MEMBER' 
          : 'APPROVE_VOLUNTEER';
    } else if (action == 'Reject') {
      finalAction = 'REJECT';
    } else if (action == 'Interview') {
      finalAction = 'INTERVIEW';
    }

    bool success = await _authService.updateUserStatus(
       userId,
       finalAction,
       reason: reason,
       date: date,
       link: link,
       interviewerId: staffId // <--- FIX: Change 'staffId' to 'interviewerId' here
    );

    setState(() { _isLoading = false; });

    if (success) {
       // --- NEW FEEDBACK ---
       if (action == 'Interview') {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Interview Scheduled & Chat Room Created!'),
             backgroundColor: Colors.green,
           ),
         );
       } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('User status updated to $action'), backgroundColor: Colors.green),
         );
       }
      _loadPendingUsers(); // Refresh the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRejectDialog(int userId) {
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
                _updateUser(userId, 'Reject', 'N/A', reason: selectedReason);
              },
              child: const Text('Reject & Notify'),
            ),
          ],
        );
      },
    );
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
              final filteredStaff = staffList.where((staff) {
                final name = staff['name'].toString().toLowerCase();
                return name.contains(searchText.toLowerCase());
              }).toList();
              
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Expanded(
                      child: ListView.builder(
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
                              Navigator.pop(context); 
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

  // --- NEW: SCHEDULE DIALOG WITH SEARCHABLE STAFF ---
  void _showScheduleDialog(PendingUser user) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String meetingLink = 'https://meet.google.com/abc-defg-hij';
    
    // Fetch Staff List
    List<Map<String, dynamic>> staffList = await _authService.getStaffList();
    int? selectedStaffId;
    
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Schedule Interview'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              // Helper to get display name
              String staffNameDisplay = selectedStaffId != null 
                  ? staffList.firstWhere((s) => s['id'] == selectedStaffId, orElse: () => {'name': 'Unknown'})['name']
                  : 'Select Staff *';

              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Select Date, Time & Interviewer:'),
                      const SizedBox(height: 16),
                      
                      // --- SEARCHABLE STAFF BUTTON ---
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
                      // -------------------------------
                      
                      const SizedBox(height: 16),

                      // Date Picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text("Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(), // Future dates only
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setDialogState(() => selectedDate = picked);
                        },
                      ),

                      // Time Picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
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
                      
                      const SizedBox(height: 8),

                      // Link Input
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Meeting Link',
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(text: meetingLink),
                        onChanged: (val) => meetingLink = val,
                      ),
                    ],
                  ),
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
                // Check if staff is selected manually since InputDecorator doesn't auto-validate on click
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
                  user.id, 
                  'Interview', 
                  'N/A', // App type doesn't matter for interview
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
              // Note: Ensure user.dateJoined is the Application Date now, not Reg Date
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.firstName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(
                                  user.profile.applicationType == 'MEMBERSHIP' 
                                    ? 'Applied for: Membership' 
                                    : 'Applied for: Volunteer',
                                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                                ),
                                Text('Applied $daysAgo days ago', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ApplicantProfileScreen(user: user),
                                ),
                              );
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
                            onPressed: () => _updateUser(user.id, 'Approve', user.profile.applicationType),
                          ),
                          _buildActionButton(
                            text: 'Reject',
                            color: Colors.red,
                            onPressed: () => _showRejectDialog(user.id),
                          ),
                          _buildActionButton(
                            text: 'Interview',
                            color: Colors.white,
                            textColor: Colors.blue.shade700,
                            borderColor: Colors.blue.shade700,
                            // --- FIX: Call the Schedule Dialog ---
                            onPressed: () => _showScheduleDialog(user), 
                            // -------------------------------------
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