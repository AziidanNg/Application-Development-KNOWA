// lib/screens/admin_create_event_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:knowa_frontend/services/event_service.dart';
import 'package:knowa_frontend/models/event.dart';

class AdminCreateEventScreen extends StatefulWidget {
  final Event? eventToEdit;
  const AdminCreateEventScreen({super.key, this.eventToEdit});

  @override
  State<AdminCreateEventScreen> createState() => _AdminCreateEventScreenState();
}

class _AdminCreateEventScreenState extends State<AdminCreateEventScreen> {
  // --- 1. SIMPLIFIED STATE VARIABLES ---
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();
  final _imagePicker = ImagePicker();

  // Text Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _crewCapacityController = TextEditingController();
  final _locationController = TextEditingController();

  // Event Data
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isOnline = true;
  String _visibility = 'DRAFT';
  
  // Image Data
  XFile? _imageFile;
  String? _existingImageUrl;
  
  // UI State
  bool _isLoading = false;
  bool get _isEditMode => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final event = widget.eventToEdit!;
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _capacityController.text = event.capacityParticipants.toString();
    _crewCapacityController.text = event.capacityCrew.toString();
    _locationController.text = event.location;
    _selectedDate = event.startTime;
    _selectedStartTime = TimeOfDay.fromDateTime(event.startTime);
    _selectedEndTime = TimeOfDay.fromDateTime(event.endTime);
    _isOnline = event.isOnline;
    _visibility = event.status;
    _existingImageUrl = event.imageUrl;
  }

  // --- 2. LOGIC FIXES IN SUBMIT ---
  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDate == null || _selectedStartTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date, Start Time, and End Time.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    // Combine Date + Time
    final startDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedStartTime!.hour, _selectedStartTime!.minute
    );
    
    final endDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedEndTime!.hour, _selectedEndTime!.minute
    );

    // FIX: Check if End Time is before Start Time
    if (endDateTime.isBefore(startDateTime)) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot be before Start time.')),
      );
      return;
    }

    // Prepare Data
    final Map<String, dynamic> result;
    final int capacity = int.tryParse(_capacityController.text) ?? 50;
    final int crewCapacity = int.tryParse(_crewCapacityController.text) ?? 10;

    // Call Service
    if (_isEditMode) {
      result = await _eventService.updateEvent(
        widget.eventToEdit!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        startTime: startDateTime.toIso8601String(),
        endTime: endDateTime.toIso8601String(),
        capacityParticipants: capacity,
        capacityCrew: crewCapacity,
        status: _visibility,
        isOnline: _isOnline,
        calendarLink: '', 
        imageFile: _imageFile,
      );
    } else {
      result = await _eventService.createEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        startTime: startDateTime.toIso8601String(),
        endTime: endDateTime.toIso8601String(),
        capacityParticipants: capacity,
        capacityCrew: crewCapacity,
        status: _visibility,
        isOnline: _isOnline,
        calendarLink: '',
        imageFile: _imageFile,
      );
    }

    setState(() { _isLoading = false; });

    if (!mounted) return;

    if (result['success']) {
      Navigator.of(context).pop(true); // Return success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['error']}')),
      );
    }
  }

  // --- 3. FIX: DATE PICKER RESTRICTION ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      // FIX: Set firstDate to NOW to prevent past dates
      firstDate: DateTime.now(), 
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() { _selectedDate = picked; });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        _existingImageUrl = null;
      });
    }
  }

  InputDecoration _buildInputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              // Title
              TextFormField(
                controller: _titleController,
                decoration: _buildInputDecoration(hint: 'Event Title'),
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Image Picker
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
                      : (_existingImageUrl != null)
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
                constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 52) / 2, minHeight: 40.0),
                children: const [Text('Online'), Text('Offline')],
              ),
              const SizedBox(height: 16),

              // Location / Link
              TextFormField(
                controller: _locationController,
                decoration: _buildInputDecoration(
                  hint: _isOnline ? 'Online Meeting Link (e.g. Zoom)' : 'Event Location (Address)',
                ),
                validator: (value) => value!.isEmpty ? 'This field is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration(hint: 'Event Description...').copyWith(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              // Capacities
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      decoration: _buildInputDecoration(hint: 'Participants'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _crewCapacityController,
                      decoration: _buildInputDecoration(hint: 'Crew'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Visibility
              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: _buildInputDecoration(hint: 'Visibility'),
                items: const [
                  DropdownMenuItem(value: 'DRAFT', child: Text('Draft (Hidden)')),
                  DropdownMenuItem(value: 'PUBLISHED', child: Text('Published (Visible)')),
                ],
                onChanged: (value) => setState(() => _visibility = value!),
              ),
              const SizedBox(height: 32),

              // Submit Button
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
}