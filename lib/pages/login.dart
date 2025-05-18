import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import your different stakeholder pages here
// import 'pages/995_operator_home.dart';
// import 'pages/ambulance_dispatchers_home.dart';
// import 'pages/citizen_home.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

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
                        color: const Color(0xFF4481EB).withOpacity(0.1),
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
                onTap: () => _navigateToRole(context, "operator"),
              ),
              
              const SizedBox(height: 16),
              
              _buildRoleCard(
                context,
                title: "Ambulance Dispatcher",
                description: "First responders and dispatchers",
                icon: Icons.local_hospital,
                color: const Color(0xFF4481EB),
                onTap: () => _navigateToRole(context, "dispatcher"),
              ),
              
              const SizedBox(height: 16),
              
              _buildRoleCard(
                context,
                title: "Citizen",
                description: "Community member access",
                icon: Icons.person,
                color: const Color(0xFF34A853),
                onTap: () => _navigateToRole(context, "citizen"),
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
              color: Colors.black.withOpacity(0.05),
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
                color: color.withOpacity(0.1),
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
  
  void _navigateToRole(BuildContext context, String role) {
    // Navigation logic based on user role
    switch (role) {
      case "operator":
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const OperatorHomePage()),
        // );
        _showComingSoonDialog(context, "995 Operator");
        break;
      case "dispatcher":
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const DispatcherHomePage()),
        // );
        _showComingSoonDialog(context, "Ambulance Dispatcher");
        break;
      case "citizen":
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const CitizenHomePage()),
        // );
        _showComingSoonDialog(context, "Citizen");
        break;
    }
  }
  
  void _showComingSoonDialog(BuildContext context, String role) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("$role Interface"),
          content: Text("The $role interface is being implemented. This would navigate to the appropriate home page."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}