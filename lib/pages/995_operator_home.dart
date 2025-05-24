import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Renamed this class to match what main.dart expects
class Operator995Home extends StatefulWidget {
  const Operator995Home({super.key});

  @override
  State<Operator995Home> createState() => _Operator995HomeState();
}

class _Operator995HomeState extends State<Operator995Home> {
  final _formKey = GlobalKey<FormState>();
  
  // Emergency case details
  String _emergencyType = 'Medical';
  String _victimCondition = 'Conscious';
  String _location = 'Jurong East St 21';
  String _description = 'Suspected heat stroke, currently experiencing hyperventilation';
  
  // Steps in the dispatch protocol
  final List<Map<String, dynamic>> _protocolSteps = [
    {'title': 'Type of Emergency', 'isCompleted': false},
    {'title': 'Victim Status', 'isCompleted': false},
    {'title': 'Location Details', 'isCompleted': false},
    {'title': 'Dispatch Resources', 'isCompleted': false},
    {'title': 'Provide Instructions', 'isCompleted': false},
  ];
  
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: OperatorNavigationBar(
          currentIndex: 0,
          onTap: (index) {},
        ),
      ),
      body: Column(
        children: [
          // Emergency Case Timer
          Container(
            color: const Color(0xFFEA4335),
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Call Duration: 02:45',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // End call logic
                  },
                  icon: const Icon(Icons.call_end, size: 16),
                  label: const Text('End Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFEA4335),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Protocol Steps
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Protocol',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _protocolSteps.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: index <= _currentStep 
                                  ? const Color(0xFFEA4335)
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: _protocolSteps[index]['isCompleted']
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : Text(
                                      '${index + 1}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _protocolSteps[index]['title'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: index == _currentStep
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: index <= _currentStep
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Current Step Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _protocolSteps[_currentStep]['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Form fields based on current step
                    if (_currentStep == 0) ...[
                      // Type of Emergency
                      _buildDropdownField(
                        label: 'Emergency Type',
                        value: _emergencyType,
                        items: const ['Medical', 'Traffic Accident', 'Fire', 'Crime', 'Other'],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _emergencyType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Emergency Description',
                        hint: 'Brief description of the emergency',
                        onChanged: (value) {
                          setState(() {
                            _description = value;
                          });
                        },
                        maxLines: 3,
                      ),
                    ],
                    
                    if (_currentStep == 1) ...[
                      // Victim Status
                      _buildDropdownField(
                        label: 'Victim Condition',
                        value: _victimCondition,
                        items: const ['Conscious', 'Unconscious', 'Critical', 'Stable', 'Unknown'],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _victimCondition = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Number of Victims',
                        hint: 'How many people are affected?',
                        keyboardType: TextInputType.number,
                        onChanged: (value) {},
                      ),
                      const SizedBox(height: 16),
                      _buildCheckboxList(
                        label: 'Symptoms',
                        options: const [
                          'Breathing difficulty',
                          'Chest pain',
                          'Bleeding',
                          'Unconscious',
                          'Burns',
                          'Trauma',
                        ],
                      ),
                    ],
                    
                    if (_currentStep == 2) ...[
                      // Location Details
                      _buildTextField(
                        label: 'Address',
                        hint: 'Street address of the emergency',
                        onChanged: (value) {
                          setState(() {
                            _location = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Landmarks',
                        hint: 'Any nearby landmarks to help identify the location',
                        onChanged: (value) {},
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Floor/Unit',
                              hint: 'If applicable',
                              onChanged: (value) {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: 'Building',
                              hint: 'If applicable',
                              onChanged: (value) {},
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_currentStep == 3) ...[
                      // Dispatch Resources
                      _buildCheckboxList(
                        label: 'Resources Needed',
                        options: const [
                          'Ambulance',
                          'Fire Truck',
                          'Police',
                          'Specialized Equipment',
                          'Medical Team',
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Additional Resources',
                        hint: 'Any other resources needed',
                        onChanged: (value) {},
                      ),
                    ],
                    
                    if (_currentStep == 4) ...[
                      // Provide Instructions
                      _buildCheckboxList(
                        label: 'Instructions Given',
                        options: const [
                          'Basic first aid',
                          'CPR instructions',
                          'Bleeding control',
                          'Evacuation guidance',
                          'Stay on the line',
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Notes for Emergency Responders',
                        hint: 'Any important details for the responding team',
                        onChanged: (value) {},
                        maxLines: 3,
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Next/Complete buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _currentStep--;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEA4335),
                              side: const BorderSide(color: Color(0xFFEA4335)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: Text(
                              'Previous',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          const SizedBox(),
                        ElevatedButton(
                          onPressed: () {
                            // Mark current step as completed
                            setState(() {
                              _protocolSteps[_currentStep]['isCompleted'] = true;
                              
                              if (_currentStep < _protocolSteps.length - 1) {
                                _currentStep++;
                              } else {
                                // All steps completed
                                _showCompletionDialog();
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA4335),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            _currentStep < _protocolSteps.length - 1 ? 'Next' : 'Complete',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.mic,
                      color: _isRecording ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRecording ? 'Recording...' : 'Tap to speak',
                      style: GoogleFonts.poppins(
                        color: _isRecording ? Colors.red : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEA4335).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  // Toggle recording
                  setState(() {
                    _isRecording = !_isRecording;
                  });
                },
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: const Color(0xFFEA4335),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required String label,
    required String hint,
    required Function(String) onChanged,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEA4335), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
        ),
      ],
    );
  }
  
  Widget _buildCheckboxList({
    required String label,
    required List<String> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...options.map((option) {
          return CheckboxListTile(
            title: Text(
              option,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            value: false,
            onChanged: (value) {},
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }),
      ],
    );
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Protocol Completed',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'All emergency protocol steps have been completed. Resources have been dispatched.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  bool _isRecording = false;
}

class OperatorNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const OperatorNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 995 Operator doesn't need a standard navigation bar
    // Instead, we'll create a simple app bar that shows their current case
    return AppBar(
      backgroundColor: const Color(0xFFEA4335),
      elevation: 0,
      title: Text(
        'Active Emergency Case',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // Case status indicator
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}