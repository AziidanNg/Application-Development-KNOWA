// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening links
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers for text fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); 
  final _passwordController = TextEditingController();

  // --- NEW: This will store the full phone number (e.g., "+60123456789") ---
  String _fullPhoneNumber = '';

  // State for toggles
  bool _isLoading = false;
  bool _agreeToPDPA = false;
  final Set<String> _selectedInterests = {};
  final List<String> _interestOptions = [
    'Education', 'Environment', 'Arts', 'Technology', 'Community'
  ];

  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return; // Check all validators

    if (!_agreeToPDPA) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the Personal Data Protection policy.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final result = await _authService.registerUser(
      name: _nameController.text,
      email: _emailController.text,
      phone: _fullPhoneNumber, // <-- Send the full phone number
      password: _passwordController.text,
      interests: _selectedInterests.toList(),
    );

    setState(() { _isLoading = false; });
    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please wait for admin approval.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Go back to login
    } else {
      // ... (error handling code is the same) ...
      String errorMsg = "An unknown error occurred.";
      if (result['error'] is Map) {
         final errorMap = result['error'] as Map;
         if (errorMap.containsKey('username')) {
            errorMsg = errorMap['username'][0];
         } else if (errorMap.containsKey('email')) {
            errorMsg = errorMap['email'][0];
         } else {
            errorMsg = errorMap.values.first[0];
         }
      } else {
         errorMsg = result['error'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Failed: $errorMsg'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _launchPDPAUrl() async {
    final Uri url = Uri.parse('https://drive.google.com/file/d/15E83ZGclaaJ10JMjefxc_kymfy9L_qAw/view?usp=drive_link'); //PDF
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open policy document.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- UPDATED "Name" field with validation ---
              _buildTextField(
                label: 'Name', 
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  // NEW: Check for numbers
                  if (RegExp(r'[0-9]').hasMatch(value)) {
                    return 'Name cannot contain numbers';
                  }
                  return null;
                }
              ),

              _buildTextField(
                label: 'Email', 
                controller: _emailController, 
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                }
              ),

              // --- NEW: Phone Number Field ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 8),
                    IntlPhoneField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: 'Enter your phone',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      initialCountryCode: 'MY', // Default to Malaysia
                      onChanged: (phone) {
                        _fullPhoneNumber = phone.completeNumber; // Stores "+6012345678"
                      },
                      // This disables the package's strict (and incorrect) validation
                      disableLengthCheck: true,
                      validator: (value) {
                         if (value == null || value.number.isEmpty) {
                           return 'Please enter your phone number';
                         }
                         return null;
                      },
                    ),
                  ],
                ),
              ),

              // --- UPDATED "Password" field with validation ---
              _buildTextField(
                label: 'Password', 
                controller: _passwordController, 
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  // NEW: Strong password checks
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  if (!value.contains(RegExp(r'[A-Z]'))) {
                    return 'Must contain at least one capital letter';
                  }
                  if (!value.contains(RegExp(r'[a-z]'))) {
                    return 'Must contain at least one small letter';
                  }
                  if (!value.contains(RegExp(r'[0-9]'))) {
                    return 'Must contain at least one number';
  }
  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                    return 'Must contain at least one symbol';
                  }
                  return null;
                }
              ),

              const SizedBox(height: 24),
              const Text('Interests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),

              // ... (Interest Chips code is the same) ...
              Wrap(
                spacing: 8.0,
                children: _interestOptions.map((interest) {
                  final bool isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                    selectedColor: Colors.blue.shade100,
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade300)
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ... (PDPA Checkbox code is the same) ...
              Row(
                children: [
                  Checkbox(
                    value: _agreeToPDPA,
                    onChanged: (value) {
                      setState(() {
                        _agreeToPDPA = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _launchPDPAUrl,
                      child: const Text(
                        'I agree to the Personal Data Protection...',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ... (Register Button code is the same) ...
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UPDATED Helper widget to accept a validator ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? Function(String?)? validator, // <-- NEW
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
            validator: validator ?? (value) { // <-- USE THE VALIDATOR
              if (value == null || value.isEmpty) {
                return 'Please enter your $label';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}