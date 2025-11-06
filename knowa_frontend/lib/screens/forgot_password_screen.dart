// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/reset_password_screen.dart'; 

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleResetRequest() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final result = await _authService.requestPasswordReset(_emailController.text);

    setState(() { _isLoading = false; });
    if (!mounted) return;

    // We always show a "success" message, even if the email doesn't exist
    // This prevents people from guessing emails
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('If an account with that email exists, a reset code has been sent.'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to the "Enter TAC" screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(email: _emailController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Forgot Password",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              "Enter your email address and we'll send you a code to reset your password.",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 40),

            // Email Field
            Text("Email", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Enter your email",
                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Send Code Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleResetRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Send Code", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}