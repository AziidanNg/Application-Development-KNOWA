import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart'; // Fixed import

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // THIS IS THE FUNCTION FOR THE "REGISTER" BUTTON
  void _handleRegistration() async {
  setState(() { _isLoading = true; });

  final result = await _authService.registerUser(
    _usernameController.text,
    _emailController.text,
    _passwordController.text,
  );

  setState(() { _isLoading = false; });
  if (!mounted) return;

  if (result['success']) {
    // Success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration successful! Please wait for admin approval.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop(); // Go back to login
  } else {
    // --- THIS IS THE NEW, IMPROVED ERROR HANDLING ---
    String errorMsg = "An unknown error occurred.";
    
    if (result['error'] is Map) {
      // This is a validation error from Django
      // (e.g., "username": ["this username is already taken"])
      try {
        final errorMap = result['error'] as Map;
        // Grab the very first error message to show the user.
        final firstErrorList = errorMap.values.first as List;
        errorMsg = firstErrorList.first;
      } catch (e) {
        errorMsg = "A validation error occurred.";
      }
    } else {
      // This is a simple string error (e.g., "Connection failed...")
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Create Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                // THIS BUTTON CORRECTLY CALLS _handleRegistration
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
    );
  }
}