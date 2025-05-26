import 'package:flutter/material.dart';
import 'pages/citizen_home.dart';
import 'pages/citizen_community.dart';
import 'pages/citizen_emergency.dart';
import 'pages/citizen_maps.dart';
import 'pages/user_profile/citizen_profile.dart';

// Define emergency red color for the FAB
const Color emergencyRed = Color(0xFFEA4335);
const Color primaryColor = Color(0xFF4285F4);

class BottomNavigationBarScreen extends StatefulWidget {
  const BottomNavigationBarScreen({super.key});

  @override
  State<BottomNavigationBarScreen> createState() => _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int _selectedIndex = 0;

  // Pages - now using the actual page widgets
  final List<Widget> _pages = [
    const CitizenHomePage(),
    const CitizenMapsPage(),
    const SizedBox(), // Emergency button placeholder
    const CitizenCommunityPage(),
    const CitizenProfilePage(),
  ];

  void _onItemTapped(int index) {
    // If selecting the middle tab, show emergency reporting page
    if (index == 2) {
      _showEmergencyReportingPage();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showEmergencyReportingPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CitizenEmergencyPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex == 2 ? 0 : _selectedIndex], // Fallback to home if middle tab
      
      // Emergency floating action button
      floatingActionButton: SizedBox(
        height: 60.0,
        width: 60.0,
        child: FloatingActionButton(
          onPressed: _showEmergencyReportingPage,
          backgroundColor: emergencyRed,
          foregroundColor: Colors.white,
          elevation: 4.0,
          shape: const CircleBorder(),
          child: const Icon(Icons.warning_amber_rounded, size: 28.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // Bottom navigation bar
      bottomNavigationBar: BottomAppBar(
        notchMargin: 8.0,
        shape: const CircularNotchedRectangle(),
        height: 60,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Left side
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.map_rounded, 'Maps'),
                ],
              ),
            ),
            
            // Center spacer for FAB
            const SizedBox(width: 80),
            
            // Right side
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(3, Icons.people_rounded, 'Community'),
                  _buildNavItem(4, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    
    return InkWell(
      onTap: () => _onItemTapped(index),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}