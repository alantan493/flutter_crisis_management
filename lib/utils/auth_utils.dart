import 'package:flutter/material.dart';

// This utility class provides a consistent logout function across all pages
class AuthUtils {
  // Static method to handle logout
  static void logout(BuildContext context) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
                
                // Navigate to login screen and clear the navigation stack
                // This ensures the user can't go back to protected pages
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/', // Assuming '/' is your login route
                  (Route<dynamic> route) => false, // This removes all previous routes
                );
              },
              child: const Text('Logout'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}