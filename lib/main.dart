import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bottom_navigation_bar.dart';

// Define global colors
const Color primaryColor = Color(0xFF4285F4); // Primary blue
const Color emergencyRed = Color(0xFFEA4335); // Emergency red

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community Safety App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          secondary: const Color(0xFF34A853), // Green
        ),
        fontFamily: 'Google Sans',
      ),
      home: const BottomNavigationBarScreen(),
    );
  }
}