// lib/screens/admin_create_meeting_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:knowa_frontend/services/event_service.dart';
import 'package:knowa_frontend/widgets/participant_selector_dialog.dart';

class AdminCreateMeetingScreen extends StatefulWidget {
  // --- 1. Accept optional data to edit ---
  final Map<String, dynamic>? meetingToEdit;

  const AdminCreateMeetingScreen({super.key, this.meetingToEdit});

  @override
  State<AdminCreateMeetingScreen> createState() => _AdminCreateMeetingScreenState();
}

class _AdminCreateMeetingScreenState extends State<AdminCreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers (Initialized later in initState)
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  
  // State
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isOnline;
  
  List<int> _selectedParticipantIds = [];
  List<Map<String, dynamic>> _allPotentialParticipants = [];
  bool _isLoading = false;
  bool _isLoadingParticipants = true;

  // --- 2. Initialize Logic ---
  @override
  void initState() {
    super.initState();
    final editData = widget.meetingToEdit;

    // --- Pre-fill Text Fields ---
    _titleController = TextEditingController(text: editData?['title'] ?? '');
    _descriptionController = TextEditingController(text: editData?['description'] ?? '');
    
    // Handle location/link logic
    String loc = editData?['location'] ?? '';
    String link = editData?['meeting_link'] ?? '';
    // If it has a link, show the link. If not, show location.
    _locationController = TextEditingController(text: link.isNotEmpty ? link : loc);

    if (editData != null) {
      // --- Pre-fill Date/Time/Online Status ---
      // Note: Data from calendar is already parsed into Objects by your backend logic
      // But passing between screens usually degrades them to Strings or basic types.
      // Assuming 'date' is DateTime and 'time' is String "10:00 AM" from MyScheduleView
      
      // Default to NOW if parsing fails or just use the passed DateTime object
      _selectedDate = editData['date'] is DateTime ? editData['date'] : DateTime.now();
      
      // Parsing "10:00 AM" back to TimeOfDay is tricky. 
      // For a robust app, you should fetch the full details by ID. 
      // For now, we will default to 10am-11am to prevent crashes.
      _startTime = const TimeOfDay(hour: 10, minute: 0); 
      _endTime = const TimeOfDay(hour: 11, minute: 0); 
      
      // Check if it's online based on the meeting link
      _isOnline = (editData['meeting_link'] as String? ?? '').isNotEmpty;
      
      // We don't have the list of participant IDs in the calendar view data.
      // You would normally fetch this detail from the API.
      // For this quick implementation, the list will start empty.
    } else {
      // --- Default Values for New Meeting ---
      _selectedDate = DateTime.now();
      _startTime = const TimeOfDay(hour: 10, minute: 0);
      _endTime = const TimeOfDay(hour: 11, minute: 0);
      _isOnline = true;
    }

    _loadParticipants();
  }

  void _loadParticipants() async {
    final EventService service = EventService();
    var users = await service.getPotentialParticipants();
    if (mounted) {
      setState(() {
        _allPotentialParticipants = users;
        _isLoadingParticipants = false;
      });
    }
  }

  void _openParticipantSelector() async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) => ParticipantSelectorDialog(
        allUsers: _allPotentialParticipants,
        initiallySelectedIds: _selectedParticipantIds,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedParticipantIds = result;
      });
    }
  }
  
  // --- 3. Submit Logic (Create vs Update) ---
  void _submit() async {
     if (!_formKey.currentState!.validate()) return;
     
     // Only check participants if CREATING. If Updating, keeping empty might mean "no change" 
     if (widget.meetingToEdit == null && _selectedParticipantIds.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least one participant")));
       return;
     }

     setState(() { _isLoading = true; });

     final startDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
     final endDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);

     final data = {
       "title": _titleController.text,
       "description": _descriptionController.text,
       "start_time": startDateTime.toIso8601String(),
       "end_time": endDateTime.toIso8601String(),
       "is_online": _isOnline,
       "location": _locationController.text,
       // Only send participants if the user actually selected something
       if (_selectedParticipantIds.isNotEmpty) "participants": _selectedParticipantIds,
     };

     final EventService service = EventService();
     bool success;

     // --- Check if Editing or Creating ---
     if (widget.meetingToEdit != null) {
       success = await service.updateMeeting(widget.meetingToEdit!['id'], data);
     } else {
       success = await service.createMeeting(data);
     }
     
     setState(() { _isLoading = false; });

     if (mounted) {
       if (success) {
         Navigator.pop(context, true); // Return success
       } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Operation failed")));
       }
     }
  }

  // --- Helper for Consistent Styling ---
  InputDecoration _buildInputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.meetingToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Meeting' : 'New Meeting'), // Dynamic Title
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: _buildInputDecoration(hint: 'Meeting Title'),
                validator: (v) => v!.isEmpty ? "Please enter a title" : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                readOnly: true,
                decoration: _buildInputDecoration(
                  hint: DateFormat('E, MMM d, yyyy').format(_selectedDate),
                  icon: Icons.calendar_today_outlined,
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: _buildInputDecoration(
                        hint: _startTime.format(context),
                        icon: Icons.access_time_outlined,
                      ),
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: _buildInputDecoration(
                        hint: _endTime.format(context),
                        icon: Icons.access_time_outlined,
                      ),
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              LayoutBuilder(builder: (context, constraints) {
                return ToggleButtons(
                  isSelected: [_isOnline, !_isOnline],
                  onPressed: (index) => setState(() => _isOnline = index == 0),
                  borderRadius: BorderRadius.circular(8.0),
                  constraints: BoxConstraints.expand(width: (constraints.maxWidth - 4) / 2, height: 45),
                  children: const [Text("Online"), Text("Offline")],
                );
              }),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _locationController,
                decoration: _buildInputDecoration(
                  hint: _isOnline ? "Meeting Link" : "Location",
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _buildInputDecoration(hint: 'Description (Optional)'),
              ),

              const SizedBox(height: 24),
              
              const Text("Participants", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              InkWell(
                onTap: _isLoadingParticipants ? null : _openParticipantSelector,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group_add_outlined, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedParticipantIds.isEmpty 
                              ? (isEditing ? "Change Participants (Optional)" : "Select Participants") 
                              : "${_selectedParticipantIds.length} Participants Selected",
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedParticipantIds.isEmpty ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? "Update Meeting" : "Create Meeting", style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}