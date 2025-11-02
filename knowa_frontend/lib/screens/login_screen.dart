import 'package:flutter/material.dart';
import 'package:knowa_frontend/screens/register_screen.dart'; // Fixed import
import 'package:knowa_frontend/services/auth_service.dart'; // Fixed import
// import 'package:knowa_frontend/screens/dashboard_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // THIS IS THE FUNCTION FOR THE "LOGIN" BUTTON
  void _handleLogin() async {
    setState(() { _isLoading = true; });

    bool success = await _authService.loginUser( // <-- This correctly calls loginUser
      _usernameController.text,
      _passwordController.text,
    );

    setState(() { _isLoading = false; });
    if (!mounted) return;

    if (success) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Successful!'), backgroundColor: Colors.green),
      );
      // TODO: Navigate to Home Screen
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (context) => const DashboardScreen()),
      // );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Failed. Check username/password.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            const Text(
              "Login",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 40),
            
            // --- REPLACE WITH THIS ---
            Text("Username", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              keyboardType: TextInputType.text, // <-- Change this
              decoration: InputDecoration(
                hintText: "Enter your username", // <-- Change this
                prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text("Password", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Enter your password",
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Icon(Icons.visibility_off_outlined, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 24),
            
            Align(
              alignment: Alignment.centerRight,
              child: Text("Forgot Password?", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                // THIS BUTTON CORRECTLY CALLS _handleLogin
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account?", style: TextStyle(color: Colors.grey.shade600)),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: Text("Sign up", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}