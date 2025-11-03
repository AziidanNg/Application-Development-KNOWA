// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening links

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
  final _passwordController = TextEditingController(); // We'll add a password field

  // State for toggles
  bool _isLoading = false;
  bool _agreeToPDPA = false;
  final Set<String> _selectedInterests = {};
  final List<String> _interestOptions = [
    'Education', 'Environment', 'Arts', 'Technology', 'Community'
  ];

  void _handleRegistration() async {
    // Validate all fields
    if (!_formKey.currentState!.validate()) return;

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
      phone: _phoneController.text,
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
      String errorMsg = "An unknown error occurred.";
      if (result['error'] is Map) {
         final errorMap = result['error'] as Map;
         // Use email as username, so check both
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
    // TODO: Replace with your actual PDF URL
    final Uri url = Uri.parse('https://www.google.com'); 
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
              _buildTextField(label: 'Name', controller: _nameController),
              _buildTextField(label: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
              _buildTextField(label: 'Phone', controller: _phoneController, keyboardType: TextInputType.phone),

              // Add a password field (not in design, but required)
              _buildTextField(label: 'Password', controller: _passwordController, isPassword: true),

              const SizedBox(height: 24),
              const Text('Interests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),

              // Interest Chips
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

              // PDPA Checkbox
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
                      onTap: _launchPDPAUrl, // This will open the link
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

              // Register Button
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

  // Helper widget for TextFields
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your $label';
              }
              if (label == 'Email' && !value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}