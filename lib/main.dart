import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'citizen_bottom_navigation_bar.dart';
import 'ambulance_dispatchers_navigation_bar.dart';
import 'pages/login.dart';
import 'pages/995_operator_home.dart';

// Define global colors
const Color primaryColor = Color(0xFF4285F4); // Primary blue
const Color emergencyRed = Color(0xFFEA4335); // Emergency red
const Color secondaryGreen = Color(0xFF34A853); // Secondary green
const Color accentYellow = Color(0xFFFBBC05); // Accent yellow

// User roles
enum UserRole {
  citizen,
  ambulanceDispatcher,
  operator995,
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  UserRole? _currentRole;

  void setUserRole(UserRole role) {
    setState(() {
      _currentRole = role;
    });
  }

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
          secondary: secondaryGreen,
        ),
        fontFamily: 'Google Sans',
      ),
      home: _currentRole == null
          ? LoginScreen(onRoleSelected: setUserRole)
          : _getHomeScreenForRole(_currentRole!),
    );
  }

  Widget _getHomeScreenForRole(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return const BottomNavigationBarScreen();
      case UserRole.ambulanceDispatcher:
        return const AmbulanceDispatchersNavigationBar();
      case UserRole.operator995:
        return const Operator995Home();
    }
  }
}

// Placeholder for the LoginScreen
// In your application, you would replace this with your actual login.dart
class LoginScreen extends StatelessWidget {
  final Function(UserRole) onRoleSelected;

  const LoginScreen({super.key, required this.onRoleSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(26),  // Using withAlpha instead of withOpacity
                  shape: BoxShape.circle,
                ),
                child: const Icon(  // Using const constructor
                  Icons.health_and_safety,
                  size: 64,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Community Safety App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your role to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              _buildRoleButton(
                context,
                'Citizen',
                Icons.person,
                'Access emergency services and community resources',
                Colors.blue.shade50,
                primaryColor,
                () => onRoleSelected(UserRole.citizen),
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                'Ambulance Dispatcher',
                Icons.local_hospital,
                'Manage emergency cases and ambulance dispatch',
                Colors.green.shade50,
                secondaryGreen,
                () => onRoleSelected(UserRole.ambulanceDispatcher),
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                '995 Operator',
                Icons.call,
                'Handle emergency calls and coordinate responses',
                Colors.red.shade50,
                emergencyRed,
                () => onRoleSelected(UserRole.operator995),
              ),
              const SizedBox(height: 48),
              TextButton(
                onPressed: () {
                  // Show help or additional information
                },
                child: const Text('Need help?'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    Color backgroundColor,
    Color iconColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: iconColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}