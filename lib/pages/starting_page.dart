import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart'; // Import your login page

// Define the UserRole enum to match your main.dart
enum UserRole {
  citizen,
  ambulanceDispatcher,
  operator995,
}

class StartingPage extends StatelessWidget {
  const StartingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // App Logo & Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4481EB).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        size: 40,
                        color: Color(0xFF4481EB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Emergency Response App",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select your role to continue",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Role Selection Cards
              _buildRoleCard(
                context,
                title: "995 Operator",
                description: "Call center emergency operator",
                icon: Icons.headset_mic,
                color: const Color(0xFFEA4335),
                onTap: () => _navigateToLogin(context, UserRole.operator995),
              ),
              
              const SizedBox(height: 16),
              
              _buildRoleCard(
                context,
                title: "Ambulance Dispatcher",
                description: "First responders and dispatchers",
                icon: Icons.local_hospital,
                color: const Color(0xFF4481EB),
                onTap: () => _navigateToLogin(context, UserRole.ambulanceDispatcher),
              ),
              
              const SizedBox(height: 16),
              
              _buildRoleCard(
                context,
                title: "Citizen",
                description: "Community member access",
                icon: Icons.person,
                color: const Color(0xFF34A853),
                onTap: () => _navigateToLogin(context, UserRole.citizen),
              ),
              
              const Spacer(),
              
              // Version Info
              Center(
                child: Text(
                  "Version 1.0.0",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToLogin(BuildContext context, UserRole role) {
    // Navigate directly to your existing LoginPage
    // You can pass the role as a parameter if your LoginPage accepts it
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(), // Replace LoginWithRole with LoginPage
      ),
    );
  }
}