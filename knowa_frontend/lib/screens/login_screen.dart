// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/screens/admin_dashboard_screen.dart';
import 'package:knowa_frontend/screens/dashboard_screen.dart';
import 'package:knowa_frontend/screens/register_screen.dart';
import 'package:knowa_frontend/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- 1. ADD THIS IMPORT

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
  bool _isPasswordHidden = true;
  bool _rememberMe = false;
  
  // --- 2. ADD THIS LIFECYCLE METHOD ---
  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  // --- 3. ADD THIS NEW FUNCTION ---
  // This function runs when the app first opens
  void _loadRememberedUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedUsername = prefs.getString('remembered_username');

    if (savedUsername != null) {
      setState(() {
        _usernameController.text = savedUsername;
        _rememberMe = true;
      });
    }
  }

  // --- 4. UPDATE THIS FUNCTION ---
  void _handleLogin() async {
    setState(() { _isLoading = true; });

    // --- NEW LOGIC ---
    // Save or remove the username *before* logging in
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_username', _usernameController.text);
    } else {
      await prefs.remove('remembered_username');
    }
    // --- END OF NEW LOGIC ---

    final userData = await _authService.loginUser(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() { _isLoading = false; });
    if (!mounted) return;

    if (userData != null) {
      if (userData['is_staff'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Failed. Check username/password.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Your build method code is identical, no changes needed here) ...
    // ... (The rest of your build method) ...
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
            
            Text("Username", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController, // This is now set by _loadRememberedUser
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: "Enter your username",
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
              obscureText: _isPasswordHidden,
              decoration: InputDecoration(
                hintText: "Enter your password",
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordHidden = !_isPasswordHidden;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe, // This is now set by _loadRememberedUser
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text("Remember me"),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to Forgot Password screen
                  },
                  child: Text("Forgot Password?", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
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