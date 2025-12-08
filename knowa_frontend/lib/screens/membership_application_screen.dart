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
  final _icController = TextEditingController();

  // File placeholders
  File? _resumeFile;
  File? _idFile;
  bool _isLoading = false;
  String _applicationType = 'MEMBERSHIP';

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

  // Automatic Age Validator
  String? _validateIC(String? value) {
    if (value == null || value.isEmpty) return 'IC Number is required';

    // Remove hyphens or spaces to get just numbers
    String cleanIC = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Basic length check (Malaysian IC is 12 digits)
    if (cleanIC.length < 12) return 'IC Number must be 12 digits';

    // Extract Date parts
    try {
      int year = int.parse(cleanIC.substring(0, 2));
      int month = int.parse(cleanIC.substring(2, 4));
      int day = int.parse(cleanIC.substring(4, 6));

      // Determine Century (1900s or 2000s)
      // Assuming current year is 2025. If YY > 25, it's 19YY. If YY <= 25, it's 20YY.
      int currentYearTwoDigits = 25; 
      int fullYear = (year > currentYearTwoDigits) ? 1900 + year : 2000 + year;

      DateTime birthDate = DateTime(fullYear, month, day);
      DateTime today = DateTime.now();

      // Calculate Age
      int age = today.year - birthDate.year;
      // Adjust if birthday hasn't happened yet this year
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      if (age < 18) {
        return 'You are $age years old. Minimum age is 18.';
      }
    } catch (e) {
      return 'Invalid Date in IC';
    }

    return null; // Valid
  }

  // Function to submit the application
  void _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    final result = await _authService.applyForMembership(
      applicationType: _applicationType,
      education: _educationController.text,
      occupation: _occupationController.text,
      reason: _reasonController.text,
      icNumber: _icController.text,
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
      Navigator.of(context).pop(true); // Go back to the dashboard
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
              const Text('I want to apply for:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _applicationType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'MEMBERSHIP',
                    child: Text('Full Membership (with fee)'),
                  ),
                  DropdownMenuItem(
                    value: 'VOLUNTEER',
                    child: Text('Project-Based Volunteer'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _applicationType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _icController, // Uses the controller you already created
                label: 'IC Number (Identity Card)',
                hint: 'e.g. 990101-01-1234',
                keyboardType: TextInputType.number,
                icon: Icons.badge_outlined,
                validator: _validateIC,
              ),
              const SizedBox(height: 16),

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

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel, size: 18, color: Colors.blue.shade800),
                        const SizedBox(width: 8),
                        Text(
                          'Legal & Compliance',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildComplianceRow('Applicants must be 18 years or older.'),
                    const SizedBox(height: 4),
                    _buildComplianceRow('PDPA Notice: Your IC and details are strictly for verification and will not be shared externally.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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

  Widget _buildComplianceRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, size: 16, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[800]))),
      ],
    );
  }

  // Helper widget for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    String? Function(String?)? validator,
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
              prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
            validator: validator ?? (value) {
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