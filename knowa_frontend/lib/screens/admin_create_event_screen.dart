// lib/screens/admin_create_event_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:knowa_frontend/services/event_service.dart';
import 'package:knowa_frontend/models/event.dart'; // Import the Event model
import 'package:image_picker/image_picker.dart';

class AdminCreateEventScreen extends StatefulWidget {
  // --- NEW: It can now optionally receive an event to edit ---
  final Event? eventToEdit;

  const AdminCreateEventScreen({super.key, this.eventToEdit});

  @override
  State<AdminCreateEventScreen> createState() => _AdminCreateEventScreenState();
}

class _AdminCreateEventScreenState extends State<AdminCreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _calendarLinkController = TextEditingController();
  final _locationController = TextEditingController();

  // State
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isOnline = true;
  String _visibility = 'DRAFT';
  bool _isLoading = false;

  final _imagePicker = ImagePicker();
  XFile? _imageFile;
  String? _existingImageUrl; // To show the event's current image

  // --- NEW: Check if we are in "Edit Mode" ---
  bool get _isEditMode => widget.eventToEdit != null;

  // --- NEW: This function pre-fills the form ---
  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // We are editing, so fill all the fields
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _capacityController.text = event.capacity.toString();
      _calendarLinkController.text = event.calendarLink ?? '';
      _locationController.text = event.location;
      _selectedDate = event.startTime;
      _selectedStartTime = TimeOfDay.fromDateTime(event.startTime);
      _selectedEndTime = TimeOfDay.fromDateTime(event.endTime);
      _isOnline = event.isOnline;
      _visibility = event.status;
      _existingImageUrl = event.imageUrl;
    }
  }

  // --- RENAMED: from _handleCreateEvent to _handleSubmit ---
  void _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedStartTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final startDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedStartTime!.hour, _selectedStartTime!.minute);
    final endDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedEndTime!.hour, _selectedEndTime!.minute);

    // This is the data we will send
    final eventData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'location': _locationController.text,
      'startTime': startDateTime.toIso8601String(),
      'endTime': endDateTime.toIso8601String(),
      'capacity': int.tryParse(_capacityController.text) ?? 50,
      'status': _visibility,
      'isOnline': _isOnline,
      'calendarLink': _calendarLinkController.text,
      'imageFile': _imageFile,
    };

    // --- NEW: Decide whether to create or update ---
    final Map<String, dynamic> result;
    if (_isEditMode) {
      // Call the UPDATE function
      result = await _eventService.updateEvent(
        widget.eventToEdit!.id,
        title: eventData['title'] as String,
        description: eventData['description'] as String,
        location: eventData['location'] as String,
        startTime: eventData['startTime'] as String,
        endTime: eventData['endTime'] as String,
        capacity: eventData['capacity'] as int,
        status: eventData['status'] as String,
        isOnline: eventData['isOnline'] as bool,
        calendarLink: eventData['calendarLink'] as String?,
        imageFile: eventData['imageFile'] as XFile?,
      );
    } else {
      // Call the CREATE function
      result = await _eventService.createEvent(
        title: eventData['title'] as String,
        description: eventData['description'] as String,
        location: eventData['location'] as String,
        startTime: eventData['startTime'] as String,
        endTime: eventData['endTime'] as String,
        capacity: eventData['capacity'] as int,
        status: eventData['status'] as String,
        isOnline: eventData['isOnline'] as bool,
        calendarLink: eventData['calendarLink'] as String?,
        imageFile: eventData['imageFile'] as XFile?,
      );
    }

    setState(() { _isLoading = false; });
    if (!mounted) return;

    if (result['success']) {
      Navigator.of(context).pop(true); // Send 'true' back to refresh the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save event: ${result['error']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // --- NEW: Dynamic title ---
        title: Text(_isEditMode ? 'Edit Event' : 'New Event'),
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
              // Event Title
              TextFormField(
                controller: _titleController,
                decoration: _buildInputDecoration(hint: 'Event Title'),
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // --- NEW: Image Picker now shows existing image ---
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: InkWell(
                  onTap: _pickImage,
                  child: _imageFile != null
                      ? Image.file(File(_imageFile!.path), fit: BoxFit.cover)
                      : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                          ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Add Event Image', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),

              // Date Picker
              TextFormField(
                readOnly: true,
                // --- NEW: Pre-fills the hint text ---
                decoration: _buildInputDecoration(
                  hint: _selectedDate == null ? 'Select Date' : DateFormat('E, MMM d, yyyy').format(_selectedDate!),
                  icon: Icons.calendar_today_outlined,
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Time Pickers
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: _buildInputDecoration(
                        hint: _selectedStartTime == null ? 'Start Time' : _selectedStartTime!.format(context),
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
                        hint: _selectedEndTime == null ? 'End Time' : _selectedEndTime!.format(context),
                        icon: Icons.access_time_outlined,
                      ),
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Online/Offline Toggle
              ToggleButtons(
                isSelected: [_isOnline, !_isOnline],
                onPressed: (index) {
                  setState(() { _isOnline = index == 0; });
                },
                borderRadius: BorderRadius.circular(8.0),
                constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 50) / 2, minHeight: 40.0),
                children: const [Text('Online'), Text('Offline')],
              ),
              const SizedBox(height: 16),

              if (!_isOnline)
                TextFormField(
                  controller: _locationController,
                  decoration: _buildInputDecoration(hint: 'Event Location'),
                  validator: (value) => !_isOnline && value!.isEmpty ? 'Please enter a location' : null,
                ),

              if (!_isOnline) const SizedBox(height: 16),

              const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration(hint: 'Enter event details...').copyWith(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              // Capacity
              TextFormField(
                controller: _capacityController,
                decoration: _buildInputDecoration(hint: 'Capacity'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter a capacity' : null,
              ),
              const SizedBox(height: 16),

              // Calendar Link
              TextFormField(
                controller: _calendarLinkController,
                decoration: _buildInputDecoration(hint: 'Calendar Link (Optional)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Visibility Dropdown
              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: _buildInputDecoration(hint: 'Visibility'),
                items: const [
                  DropdownMenuItem(value: 'DRAFT', child: Text('Draft (Hidden)')),
                  DropdownMenuItem(value: 'PUBLISHED', child: Text('Published (Visible)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _visibility = value!;
                  });
                },
              ),
              const SizedBox(height: 32),

              // --- NEW: Dynamic button text ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditMode ? 'Update Event' : 'Create Event', style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Your _buildInputDecoration, _selectDate, and _selectTime helpers are here) ...

  // Helper to pick an image
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        _existingImageUrl = null; // Clear existing image if a new one is picked
      });
    }
  }

  // Helper function for text field styling
  InputDecoration _buildInputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Function to show the Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to show the Time Picker
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime 
        ? (_selectedStartTime ?? TimeOfDay.now())
        : (_selectedEndTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
        } else {
          _selectedEndTime = picked;
        }
      });
    }
  }
}