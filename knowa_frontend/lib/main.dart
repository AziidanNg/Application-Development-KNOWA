// lib/main.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/screens/splash_screen.dart';
import 'package:knowa_frontend/screens/login_screen.dart'; 
import 'package:knowa_frontend/widgets/global_chatbot.dart';
import 'package:knowa_frontend/services/local_notification_service.dart'; 

void main() async {
  // --- 2. INITIALIZE SERVICES BEFORE APP RUNS ---
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KNOWA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class AppRootWrapper extends StatelessWidget {
  final Widget child;
  final double bottomNavOffset; // Used to push Chatbot up if Nav Bar is present

  const AppRootWrapper({
    super.key, 
    required this.child,
    this.bottomNavOffset = 0, // Default 0 for Login/Register
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Global Chatbot is always on top, adjusted by offset
        GlobalChatbot(additionalBottomPadding: bottomNavOffset), 
      ],
    );
  }
}