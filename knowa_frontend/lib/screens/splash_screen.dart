// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/main.dart'; // To use AppRootWrapper
import 'package:knowa_frontend/screens/login_screen.dart';
import 'package:knowa_frontend/screens/main_navigation_screen.dart';
import 'package:knowa_frontend/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      // This now validates the token with the backend!
      final userData = await _authService.getUserData(); 

      if (userData != null) {
        // Token is GOOD -> Go to Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AppRootWrapper(
              child: MainNavigationScreen(userData: userData),
              bottomNavOffset: 70, 
            ),
          ),
        );
      } else {
        // Token is BAD (401) or Null -> Go to Login
        _goToLogin();
      }
    } catch (e) {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AppRootWrapper(
          child: LoginScreen(),
          // Default offset (0) is fine for login
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match your app theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- YOUR LOGO HERE ---
            // Replace this Icon with Image.asset('assets/logo.png') if you have one
            Icon(Icons.volunteer_activism, size: 100, color: Colors.blue.shade700),
            
            const SizedBox(height: 24),
            
            Text(
              "KNOWA",
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                color: Colors.blue.shade700,
                letterSpacing: 2.0,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading Spinner
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}