import 'package:flutter/material.dart';
import 'pages/ambulance_dispatchers_home.dart';

class CurrentCasePage extends StatelessWidget {
  const CurrentCasePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for the current case
    final Map<String, dynamic> currentCase = {
      'id': 'C-001',
      'patientName': 'John Doe',
      'age': 54,
      'gender': 'Male',
      'location': '21 Jurong West Street 32, #12-456',
      'description': 'Showing symptoms of cardiac arrest',
      'status': 'En route',
      'severity': 'Critical',
      'callerNumber': '+65 9123 4567',
      'dispatchTime': DateTime.now().subtract(const Duration(minutes: 8)),
      'estimatedArrival': DateTime.now().add(const Duration(minutes: 3)),
      'vitalSigns': [
        {'name': 'Consciousness', 'value': 'Unconscious'},
        {'name': 'Breathing', 'value': 'Irregular'},
        {'name': 'Pulse', 'value': 'Weak'},
      ],
      'interventions': [
        'CPR in progress by hotel staff',
        'AED advised but not yet applied',
      ],
      'medicalHistory': 'Previous heart condition, on medication for hypertension',
      'allergies': 'Penicillin',
      'responders': [
        {'name': 'Paramedic Kenna', 'role': 'Lead Paramedic'},
        {'name': 'Officer Tan', 'role': 'EMT'},
      ],
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Emergency Case'),
        backgroundColor: Colors.red.shade100,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CASE ${currentCase['id']} - ${currentCase['severity'].toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      currentCase['status'],
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // ETA section
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'ETA: ${_formatTime(currentCase['estimatedArrival'])}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${_formatTimeRemaining(currentCase['estimatedArrival'])})',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Patient info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Divider(),
                      _infoRow('Name', currentCase['patientName']),
                      _infoRow('Age', currentCase['age'].toString()),
                      _infoRow('Gender', currentCase['gender']),
                      _infoRow('Medical History', currentCase['medicalHistory']),
                      _infoRow('Allergies', currentCase['allergies']),
                    ],
                  ),
                ),
              ),
            ),

            // Location section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Divider(),
                      _infoRow('Address', currentCase['location']),
                      const SizedBox(height: 12),
                      Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Text('Map View'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Launch navigation
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Start Navigation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Vital signs section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vital Signs & Interventions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Divider(),
                      
                      // Vital signs
                      ...currentCase['vitalSigns'].map<Widget>((vital) {
                        return _infoRow(vital['name'], vital['value']);
                      }).toList(),
                      
                      const SizedBox(height: 16),
                      const Text(
                        'Current Interventions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Interventions
                      ...currentCase['interventions'].map<Widget>((intervention) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(intervention)),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),

            // Responders section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Responders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Divider(),
                      
                      // Responders
                      ...currentCase['responders'].map<Widget>((responder) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.person, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    responder['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    responder['role'],
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),

            // Communication and actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Communications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Divider(),
                      _infoRow('Caller', currentCase['callerNumber']),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _actionButton(
                            icon: Icons.phone,
                            label: 'Call Caller',
                            color: Colors.green,
                            onPressed: () {
                              // Make call
                            },
                          ),
                          _actionButton(
                            icon: Icons.video_call,
                            label: 'Video Connect',
                            color: Colors.blue,
                            onPressed: () {
                              // Start video call
                            },
                          ),
                          _actionButton(
                            icon: Icons.message,
                            label: 'Send SMS',
                            color: Colors.orange,
                            onPressed: () {
                              // Send SMS
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Case update section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Case Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statusButton(
                            label: 'Arrived',
                            color: Colors.blue,
                            onPressed: () {
                              // Update status
                            },
                          ),
                          _statusButton(
                            label: 'Patient Contact',
                            color: Colors.orange,
                            onPressed: () {
                              // Update status
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statusButton(
                            label: 'En Route to Hospital',
                            color: Colors.purple,
                            onPressed: () {
                              // Update status
                            },
                          ),
                          _statusButton(
                            label: 'Case Completed',
                            color: Colors.green,
                            onPressed: () {
                              // Update status
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _statusButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
  
  String _formatTimeRemaining(DateTime eta) {
    final now = DateTime.now();
    final difference = eta.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inMinutes < 1) {
      return 'Less than a minute';
    } else {
      return '${difference.inMinutes} min remaining';
    }
  }
}

class AmbulanceDispatchersNavigationBar extends StatefulWidget {
  const AmbulanceDispatchersNavigationBar({super.key});

  @override
  State<AmbulanceDispatchersNavigationBar> createState() => _AmbulanceDispatchersNavigationBarState();
}

class _AmbulanceDispatchersNavigationBarState extends State<AmbulanceDispatchersNavigationBar> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const AmbulanceDispatchersHome(),
    const CurrentCasePage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Cases Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Current Case',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4285F4),
        onTap: _onItemTapped,
      ),
    );
  }
}

// A simple profile page placeholder
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatcher Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF4285F4),
              child: Icon(
                Icons.person,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Warrant Officer Ramy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Ambulance Dispatcher',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            _profileInfoItem(Icons.badge, 'ID', 'ADB-2023-4421'),
            _profileInfoItem(Icons.location_on, 'Station', 'Central Fire Station'),
            _profileInfoItem(Icons.timer, 'Shift', '08:00 - 20:00'),
            _profileInfoItem(Icons.phone, 'Contact', '+65 6555 1234'),
            _profileInfoItem(Icons.email, 'Email', 'ramy@scdf.gov.sg'),
            const SizedBox(height: 30),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Case History'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to case history
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to help
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logout functionality
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}