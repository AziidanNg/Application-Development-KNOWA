// lib/screens/membership_application_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:knowa_frontend/services/auth_service.dart';

class MembershipApplicationScreen extends StatefulWidget {
  const MembershipApplicationScreen({super.key});

  @override
  State<MembershipApplicationScreen> createState() => _MembershipApplicationScreenState();
}

class _MembershipApplicationScreenState extends State<MembershipApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers
  final _educationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _reasonController = TextEditingController();
  final _ageController = TextEditingController();

  // File placeholders
  File? _resumeFile;
  File? _idFile;
  bool _isLoading = false;

  // Function to pick a file
  Future<File?> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  // Function to submit the application
  void _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    final result = await _authService.applyForMembership(
      education: _educationController.text,
      occupation: _occupationController.text,
      reason: _reasonController.text,
      age: _ageController.text,
      resumeFile: _resumeFile,
      idFile: _idFile,
    );

    setState(() { _isLoading = false; });
    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted! Your status is now "Pending".'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Go back to the dashboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Application'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _ageController,
                label: 'Age',
                hint: 'Enter your age',
                keyboardType: TextInputType.number
              ),
              _buildTextField(
                controller: _educationController,
                label: 'Education',
                hint: 'e.g., Bachelor in Computer Science',
              ),
              _buildTextField(
                controller: _occupationController,
                label: 'Occupation',
                hint: 'e.g., Student or Software Engineer',
              ),

              _buildTextField(
                controller: _reasonController,
                label: 'Tell us why you\'d love to be part of our team!',
                hint: 'Reason for Joining...',
                maxLines: 5,
              ),

              const SizedBox(height: 24),
              const Text('Upload Documents (e.g., resume, ID)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Resume File Picker
              _buildFilePicker(
                label: 'Resume/CV',
                file: _resumeFile,
                onTap: () async {
                  File? file = await _pickFile();
                  if (file != null) setState(() { _resumeFile = file; });
                },
              ),

              // ID File Picker
              _buildFilePicker(
                label: 'Identification (ID)',
                file: _idFile,
                onTap: () async {
                  File? file = await _pickFile();
                  if (file != null) setState(() { _idFile = file; });
                },
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Application', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // Helper widget for file pickers
  Widget _buildFilePicker({
    required String label,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300)
          ),
          child: Row(
            children: [
              Icon(Icons.attach_file, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  file == null ? label : file.path.split('/').last,
                  style: TextStyle(
                    color: file == null ? Colors.grey[700] : Colors.black,
                    fontStyle: file == null ? FontStyle.italic : FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}