// lib/screens/verify_2fa_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:knowa_frontend/screens/admin_dashboard_screen.dart';
import 'package:knowa_frontend/screens/dashboard_screen.dart';
import 'package:knowa_frontend/screens/main_navigation_screen.dart';


class Verify2FAScreen extends StatefulWidget {
  // We must pass in the email/username from the login screen
  final String username;

  const Verify2FAScreen({super.key, required this.username});

  @override
  State<Verify2FAScreen> createState() => _Verify2FAScreenState();
}

class _Verify2FAScreenState extends State<Verify2FAScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tacController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleVerifyTAC() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final userData = await _authService.verifyTAC(
        widget.username,
        _tacController.text,
      );

      setState(() { _isLoading = false; });
      if (!mounted) return;

      if (userData != null) {
      // SUCCESS! Navigate to the main app shell.
      // Both Admins and Public Users go to the SAME navigation screen.
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(userData: userData),
          ),
          (Route<dynamic> route) => false, // 'false' means "remove all previous routes"
        );
      } else {
        // TAC was invalid or expired
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or expired code. Please try again.')),
        );
      }
    }
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Check your email",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                "We've sent a 6-digit code to ${widget.username}. Please enter it below.",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 40),

              // TAC Code Field
              TextFormField(
                controller: _tacController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Enter 6-digit code',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Please enter a valid 6-digit code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyTAC,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Verify", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              // TODO: Add a "Resend Code" button here later
            ],
          ),
        ),
      ),
    );
  }
}