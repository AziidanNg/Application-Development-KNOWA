// lib/screens/admin_create_event_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:knowa_frontend/services/event_service.dart'; // Import the service
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // To display the file

class AdminCreateEventScreen extends StatefulWidget {
  const AdminCreateEventScreen({super.key});

  @override
  State<AdminCreateEventScreen> createState() => _AdminCreateEventScreenState();
}

class _AdminCreateEventScreenState extends State<AdminCreateEventScreen> {
  final _imagePicker = ImagePicker();
  XFile? _imageFile;
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService(); // Create an instance of the service

  // Controllers for text fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _calendarLinkController = TextEditingController();
  final _locationController = TextEditingController(); // For offline location

  // State for pickers and toggles
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isOnline = true;
  String _visibility = 'DRAFT'; // Default to Draft
  bool _isLoading = false;

  Future<void> _pickImage() async {
  final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    setState(() {
      _imageFile = pickedFile;
    });
  }
  }

  // --- THIS FUNCTION IS NOW COMPLETE ---
  void _handleCreateEvent() async {
    // First, check if the form is valid
    if (_formKey.currentState!.validate() && 
        _selectedDate != null && 
        _selectedStartTime != null && 
        _selectedEndTime != null) {

      setState(() { _isLoading = true; });

      // Combine Date and Time into ISO 8601 strings for Django
      final startDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedStartTime!.hour, _selectedStartTime!.minute);
      final endDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedEndTime!.hour, _selectedEndTime!.minute);

      // Call the API service
      final result = await _eventService.createEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        startTime: startDateTime.toIso8601String(),
        endTime: endDateTime.toIso8601String(),
        capacity: int.tryParse(_capacityController.text) ?? 50,
        status: _visibility,
        isOnline: _isOnline,
        calendarLink: _calendarLinkController.text,
        imageFile: _imageFile,
      );

      setState(() { _isLoading = false; });
      if (!mounted) return;

      if (result['success']) {
        // Pop back to the event list and send 'true' to force a refresh
        Navigator.of(context).pop(true); 
      } else {
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: ${result['error']}')),
        );
      }
    } else {
      // Show a generic validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Event'),
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

              // --- ADD THIS NEW IMAGE PICKER WIDGET ---
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
                  child: _imageFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Add Event Image', style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : Image.file(
                          File(_imageFile!.path),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Date Picker
              TextFormField(
                readOnly: true,
                decoration: _buildInputDecoration(
                  hint: _selectedDate == null ? 'Select Date' : DateFormat('E, MMM d, yyyy').format(_selectedDate!),
                  icon: Icons.calendar_today_outlined,
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Time Pickers (Start and End)
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

              // Location field (only shows if "Offline" is selected)
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

              // Create Event Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // THIS IS NOW CONNECTED
                  onPressed: _isLoading ? null : _handleCreateEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Event', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      firstDate: DateTime.now(),
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