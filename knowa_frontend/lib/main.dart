import 'package:flutter/material.dart';
import 'package:knowa_frontend/screens/login_screen.dart'; // Import your new screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KNOWA',
      theme: ThemeData(
        // This applies your Google Material Design theme
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreen(), // This is the new starting point
    );
  }
}

//test