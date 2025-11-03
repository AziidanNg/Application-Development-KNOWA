import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminCreateEventScreen extends StatefulWidget {
  const AdminCreateEventScreen({super.key});

  @override
  State<AdminCreateEventScreen> createState() => _AdminCreateEventScreenState();
}

class _AdminCreateEventScreenState extends State<AdminCreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _calendarLinkController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isOnline = true; // For the "Online/Offline" toggle

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
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
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
                validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Date Picker
              TextFormField(
                readOnly: true,
                decoration: _buildInputDecoration(
                  hint: _selectedDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                  icon: Icons.calendar_today_outlined,
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Time Picker
              TextFormField(
                readOnly: true,
                decoration: _buildInputDecoration(
                  hint: _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                  icon: Icons.access_time_outlined,
                ),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 16),

              // Online/Offline Toggle
              ToggleButtons(
                isSelected: [_isOnline, !_isOnline],
                onPressed: (index) {
                  setState(() {
                    _isOnline = index == 0;
                  });
                },
                borderRadius: BorderRadius.circular(8.0),
                constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 50) / 2, minHeight: 40.0),
                children: const [
                  Text('Online'),
                  Text('Offline'),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration(hint: 'Enter event details...').copyWith(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 5,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              // Capacity
              TextFormField(
                controller: _capacityController,
                decoration: _buildInputDecoration(hint: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Calendar Link
              TextFormField(
                controller: _calendarLinkController,
                decoration: _buildInputDecoration(hint: 'Calendar Link (Optional)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              
              // Visibility (We'll hard-code as "Draft" for now)
              // ...
              
              const SizedBox(height: 32),

              // Create Event Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Connect this to the EventService to create the event
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Create Event', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build consistent text field styling
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
}