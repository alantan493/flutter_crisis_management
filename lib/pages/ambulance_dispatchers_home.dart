import 'package:flutter/material.dart';

class Case {
  final String id;
  final String patientName;
  final String location;
  final String description;
  final String status;
  final DateTime timestamp;
  final String severity;
  final String callerNumber;
  final List<String> vitalSigns;
  final String dispatcherNotes;

  Case({
    required this.id,
    required this.patientName,
    required this.location,
    required this.description,
    required this.status,
    required this.timestamp,
    required this.severity,
    required this.callerNumber,
    required this.vitalSigns,
    required this.dispatcherNotes,
  });
}

class AmbulanceDispatchersHome extends StatefulWidget {
  const AmbulanceDispatchersHome({super.key});

  @override
  State<AmbulanceDispatchersHome> createState() => _AmbulanceDispatchersHomeState();
}

class _AmbulanceDispatchersHomeState extends State<AmbulanceDispatchersHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Case> _activeCases = [];
  final List<Case> _pendingCases = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Populate with sample data for demonstration
    _loadSampleCases();
  }
  
  void _loadSampleCases() {
    // In a real app, this would come from an API or database
    _activeCases.add(
      Case(
        id: 'C-001',
        patientName: 'John Doe',
        location: '21 Jurong West Street 32, #12-456',
        description: 'Male, 54, showing symptoms of cardiac arrest',
        status: 'En route',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        severity: 'Critical',
        callerNumber: '+65 9123 4567',
        vitalSigns: ['Unconscious', 'CPR in progress by hotel staff'],
        dispatcherNotes: 'Caller is performing CPR as instructed. Video feed established.',
      ),
    );
    
    _pendingCases.add(
      Case(
        id: 'C-002',
        patientName: 'Sarah Tan',
        location: '35 Orchard Road, Lucky Plaza',
        description: 'Female, 72, difficulty breathing, possible asthma attack',
        status: 'Pending dispatch',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        severity: 'Urgent',
        callerNumber: '+65 8765 4321',
        vitalSigns: ['Conscious', 'Labored breathing', 'History of asthma'],
        dispatcherNotes: 'Patient has inhaler but not responding to medication.',
      ),
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Dispatch Center'),
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Cases'),
            Tab(text: 'Pending Cases'),
          ],
          labelColor: const Color(0xFF4285F4),
          indicatorColor: const Color(0xFF4285F4),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCasesList(_activeCases),
          _buildCasesList(_pendingCases),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to case details or refresh cases
          _showRefreshDialog();
        },
        backgroundColor: const Color(0xFF4285F4),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
  
  Widget _buildCasesList(List<Case> cases) {
    if (cases.isEmpty) {
      return const Center(
        child: Text('No cases at the moment'),
      );
    }
    
    return ListView.builder(
      itemCount: cases.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final Case caseItem = cases[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () {
              _navigateToCaseDetails(caseItem);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: _getSeverityColor(caseItem.severity).withOpacity(0.2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Case ${caseItem.id} - ${caseItem.severity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getSeverityColor(caseItem.severity),
                        ),
                      ),
                      Text(
                        _formatTimestamp(caseItem.timestamp),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caseItem.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(caseItem.description),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              caseItem.location,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(caseItem.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          caseItem.status,
                          style: TextStyle(
                            color: _getStatusColor(caseItem.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(
                        icon: Icons.directions,
                        label: 'Navigate',
                        onPressed: () {
                          // Open navigation to case location
                        },
                      ),
                      _actionButton(
                        icon: Icons.phone,
                        label: 'Call',
                        onPressed: () {
                          // Call the patient or caller
                        },
                      ),
                      _actionButton(
                        icon: Icons.assignment,
                        label: 'Details',
                        onPressed: () {
                          _navigateToCaseDetails(caseItem);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _actionButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onPressed
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF4285F4)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4285F4),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      case 'non-urgent':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en route':
        return Colors.blue;
      case 'pending dispatch':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hrs ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
  
  void _navigateToCaseDetails(Case caseItem) {
    // Navigate to the case details page
    // In a real app, you would push to a new route
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Case ${caseItem.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(caseItem.severity).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            caseItem.severity,
                            style: TextStyle(
                              color: _getSeverityColor(caseItem.severity),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detailSection('Patient', caseItem.patientName),
                    _detailSection('Description', caseItem.description),
                    _detailSection('Location', caseItem.location),
                    _detailSection('Status', caseItem.status),
                    _detailSection('Caller Number', caseItem.callerNumber),
                    
                    const SizedBox(height: 16),
                    const Text(
                      'Vital Signs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: caseItem.vitalSigns.map((vital) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 8),
                              const SizedBox(width: 8),
                              Text(vital),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    _detailSection('Dispatcher Notes', caseItem.dispatcherNotes),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Update case status
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Update Status'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          // Navigate to the location
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4285F4)),
                          foregroundColor: const Color(0xFF4285F4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Start Navigation'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _detailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  void _showRefreshDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Refresh Cases'),
          content: const Text('Do you want to refresh the case list?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // In a real app, you would fetch new cases here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cases refreshed'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Refresh'),
            ),
          ],
        );
      },
    );
  }
}