import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> with SingleTickerProviderStateMixin {
  final List<String> _emergencyTypes = [
    'Medical Emergency',
    'Traffic Accident',
    'Fire Emergency',
  ];

  String _selectedEmergency = 'Medical Emergency';
  final TextEditingController _nricController = TextEditingController();
  bool _isCallInProgress = false;
  bool _isRecording = false;
  Timer? _callDurationTimer;
  int _callDurationInSeconds = 0;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _imageFiles = [];
  int _currentPageIndex = 0;
  late PageController _pageController;
  
  // Mock transcript data
  List<Map<String, dynamic>> _transcript = [];
  
  // First aid instructions
  final List<Map<String, dynamic>> _firstAidSteps = [
    {
      "title": "Check consciousness",
      "description": "Tap the shoulder and ask if they're okay. Look for a response.",
      "isComplete": false,
    },
    {
      "title": "Control bleeding",
      "description": "Apply firm pressure to the wound with a clean cloth or bandage.",
      "isComplete": false,
    },
    {
      "title": "Keep the victim still",
      "description": "Advise the victim not to move, especially if there's a head injury.",
      "isComplete": false,
    },
    {
      "title": "Monitor vital signs",
      "description": "Check breathing and pulse regularly until help arrives.",
      "isComplete": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
    
    // Add initial transcript message
    _transcript.add({
      "speaker": "Operator", 
      "text": "Emergency services. What's your emergency?",
      "isCritical": false,
    });
  }

  @override
  void dispose() {
    _nricController.dispose();
    _callDurationTimer?.cancel();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startCall() {
    setState(() {
      _isCallInProgress = true;
      _callDurationInSeconds = 0;
      
      // Start timer for call duration
      _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _callDurationInSeconds++;
        });
        
        // Simulate receiving transcript updates
        if (_callDurationInSeconds == 3) {
          _addTranscriptMessage("You", "Someone fell and hit their head. They're bleeding from the forehead.", true);
        } else if (_callDurationInSeconds == 8) {
          _addTranscriptMessage("Operator", "Is the person conscious? How old are they?", false);
        } else if (_callDurationInSeconds == 13) {
          _addTranscriptMessage("You", "Yes, they're conscious but dizzy. It's an adult, about 40 years old.", true);
        } else if (_callDurationInSeconds == 18) {
          _addTranscriptMessage("Operator", "Is there heavy bleeding? Please check if the blood is pulsing or flowing steadily.", false);
        }
      });
    });
  }

  void _addTranscriptMessage(String speaker, String text, bool isCritical) {
    setState(() {
      _transcript.add({
        "speaker": speaker,
        "text": text,
        "isCritical": isCritical,
      });
    });
  }
  
  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _imageFiles.add(image);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully! Sending to emergency services.'))
      );
    }
  }

  void _endCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Emergency Call?'),
        content: const Text('Are you sure you want to end this emergency call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isCallInProgress = false;
                _isRecording = false;
                _callDurationTimer?.cancel();
                _transcript.clear();
                _imageFiles.clear();
                _transcript.add({
                  "speaker": "Operator", 
                  "text": "Emergency services. What's your emergency?",
                  "isCritical": false,
                });
              });
            },
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const emergencyRed = Color(0xFFEA4335);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Emergency Assistant',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: _isCallInProgress 
              ? _endCall 
              : () => Navigator.pop(context),
        ),
      ),
      body: _isCallInProgress 
          ? _buildCallInterface(emergencyRed)
          : _buildEmergencyStartPage(emergencyRed),
    );
  }

  Widget _buildCallInterface(Color primaryColor) {
    return Column(
      children: [
        // Call header with duration
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
                      ),
                      child: Icon(Icons.phone_in_talk, size: 30, color: primaryColor),
                    ),
                  );
                }
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Call (995)',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Call Duration: ${_formatDuration(_callDurationInSeconds)}',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.shade50),
                child: IconButton(
                  icon: const Icon(Icons.call_end, color: Colors.red),
                  onPressed: _endCall,
                ),
              ),
            ],
          ),
        ),
        
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3)],
          ),
          child: Row(
            children: [
              _buildTabButton(0, Icons.record_voice_over, "Transcript"),
              _buildTabButton(1, Icons.medical_services, "First Aid"),
              _buildTabButton(2, Icons.add_a_photo, "Upload Images"),
            ],
          ),
        ),
        
        // Page view for content
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: [
              _buildTranscriptView(),
              _buildFirstAidView(),
              _buildImageUploadView(),
            ],
          ),
        ),
        
        // Recording button and action bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleRecording,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording ? Colors.green.shade100 : Colors.transparent,
                          ),
                          child: Icon(
                            _isRecording ? Icons.mic : Icons.mic_off,
                            color: _isRecording ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isRecording ? "Recording... Speak clearly" : "Tap microphone to speak",
                          style: GoogleFonts.poppins(
                            color: _isRecording ? Colors.green.shade700 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.1),
                ),
                child: IconButton(
                  icon: Icon(Icons.priority_high, color: primaryColor),
                  onPressed: () {
                    // Show NRIC dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('NRIC Information'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _nricController,
                              decoration: const InputDecoration(
                                labelText: 'Victim\'s NRIC/ID',
                                hintText: 'Enter NRIC number if available',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('This will help retrieve the victim\'s medical history'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('NRIC submitted successfully'))
                              );
                            },
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTabButton(int index, IconData icon, String label) {
    final bool isSelected = _currentPageIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFFEA4335) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFFEA4335) : Colors.grey,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? const Color(0xFFEA4335) : Colors.grey,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptView() {
    return Container(
      color: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transcript.length,
        itemBuilder: (context, index) {
          final item = _transcript[index];
          return _buildTranscriptBubble(
            item["speaker"],
            item["text"],
            isCritical: item["isCritical"],
          );
        },
      ),
    );
  }

  Widget _buildFirstAidView() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Follow these first aid steps while waiting for the ambulance.",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _firstAidSteps.length,
              itemBuilder: (context, index) {
                final step = _firstAidSteps[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: step["isComplete"] ? Colors.green : Colors.grey.shade200,
                      child: Icon(
                        step["isComplete"] ? Icons.check : Icons.medical_services,
                        color: step["isComplete"] ? Colors.white : Colors.grey,
                      ),
                    ),
                    title: Text(
                      step["title"],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(step["description"], style: GoogleFonts.poppins()),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        step["isComplete"] ? Icons.refresh : Icons.check_circle_outline,
                        color: step["isComplete"] ? Colors.grey : Colors.green,
                      ),
                      onPressed: () {
                        setState(() {
                          _firstAidSteps[index]["isComplete"] = !step["isComplete"];
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadView() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Upload Images",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            "Share photos of the emergency situation to help first responders prepare",
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: Text("Take Photo", style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA4335),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _imageFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "No images uploaded yet",
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _imageFiles.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(_imageFiles[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _imageFiles.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptBubble(String speaker, String text, {required bool isCritical}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: speaker == "Operator" 
                  ? const Color(0xFF4481EB).withOpacity(0.1)
                  : const Color(0xFFEA4335).withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                speaker == "Operator" ? Icons.support_agent : Icons.person,
                size: 18,
                color: speaker == "Operator" ? const Color(0xFF4481EB) : const Color(0xFFEA4335),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCritical ? const Color(0xFFEA4335).withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isCritical
                        ? Border.all(color: const Color(0xFFEA4335).withOpacity(0.3))
                        : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyStartPage(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Emergency Type Selection
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Report Type",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedEmergency,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1E293B),
                        fontSize: 16,
                      ),
                      items: _emergencyTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _selectedEmergency = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Main Action Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEA4335), Color(0xFFFF7043)],
              ),
              boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15)],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _startCall,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.call, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Emergency Call",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "Direct call to 995 emergency services",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.record_voice_over, "Live call with emergency operator"),
                      _buildInfoRow(Icons.mic, "Call will be recorded for analysis"),
                      _buildInfoRow(Icons.location_on, "Your location will be shared"),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: _startCall,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.call, color: Color(0xFFEA4335), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "START EMERGENCY CALL",
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFEA4335),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}