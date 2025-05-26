import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/starting_page.dart';  // Test this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const StartingPage(),  // Try using StartingPage
    );
  }
}
