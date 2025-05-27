import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CitizenMedicalEmergencyPage extends StatefulWidget {
  const CitizenMedicalEmergencyPage({super.key});

  @override
  State<CitizenMedicalEmergencyPage> createState() =>
      _CitizenMedicalEmergencyPageState();
}

class _CitizenMedicalEmergencyPageState
    extends State<CitizenMedicalEmergencyPage>
    with SingleTickerProviderStateMixin {
  // Core state variables
  bool _isCallInProgress = false;
  bool _isRecording = false;
  int _callDurationInSeconds = 0;
  Timer? _callDurationTimer;
  int _currentPageIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // Firebase instances
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();

  // Upload state
  bool _isUploading = false;
  String? _emergencyCaseId;

  // Form controllers
  final TextEditingController _nricController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Image data
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _identificationImages = [];
  final List<XFile> _woundImages = [];

  // Mock data
  final List<Map<String, dynamic>> _transcript = [];
  final String _assessmentSummary =
      "Head injury with bleeding. Victim conscious but dizzy.";
  final List<String> _recommendations = [
    "Apply gentle pressure with clean cloth. Keep victim still.",
    "Monitor for confusion, severe headache, or vomiting."
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

    // Generate a unique case ID
    _emergencyCaseId = _uuid.v4();

    // Add initial transcript message
    _transcript.add({
      "speaker": "Operator",
      "text": "Emergency services. What's your emergency?",
      "isCritical": false,
    });

    // Start call immediately
    _startCall();
  }

  @override
  void dispose() {
    _nricController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _callDurationTimer?.cancel();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startCall() {
    setState(() {
      _isCallInProgress = true;
      _callDurationInSeconds = 0;

      _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _callDurationInSeconds++;
        });

        // Simulate transcript updates
        if (_callDurationInSeconds == 3) {
          _addTranscriptMessage(
              "You",
              "Someone fell and hit their head. They're bleeding from the forehead.",
              true);
        } else if (_callDurationInSeconds == 8) {
          _addTranscriptMessage(
              "Operator", "Is the person conscious? How old are they?", false);
        } else if (_callDurationInSeconds == 13) {
          _addTranscriptMessage(
              "You",
              "Yes, they're conscious but dizzy. It's an adult, about 40 years old.",
              true);
        } else if (_callDurationInSeconds == 18) {
          _addTranscriptMessage(
              "Operator",
              "Is there heavy bleeding? Please check if the blood is pulsing or flowing steadily.",
              false);
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

  Future<void> _pickWoundImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null && mounted) {
      setState(() {
        _woundImages.add(image);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Photo added'), duration: Duration(seconds: 1)));
    }
  }

  Future<void> _pickIDImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null && mounted) {
      setState(() {
        _identificationImages.add(image);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ID photo added'), duration: Duration(seconds: 1)));
    }
  }

  // Improved function to upload images to Firebase Storage
  Future<List<String>> _uploadImages(List<XFile> images, String folder) async {
    List<String> downloadUrls = [];

    if (images.isEmpty) {
      print('No images to upload');
      return downloadUrls;
    }

    for (var image in images) {
      try {
        // Print image details for debugging
        print('Uploading image: ${image.path}');
        print('Image size: ${await File(image.path).length()} bytes');

        // Create a unique filename
        final String fileName =
            '${_emergencyCaseId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef =
            _storage.ref().child('case_SCDF_medical/$folder/$fileName');

        // Create file from the image
        File imageFile = File(image.path);

        // Check if file exists
        if (!await imageFile.exists()) {
          print('Error: Image file does not exist at path: ${image.path}');
          continue;
        }

        // Upload with metadata to ensure proper content type
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'picked-from': 'camera'},
        );

        // Upload with explicit task to track progress
        final uploadTask = storageRef.putFile(imageFile, metadata);

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          print(
              'Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
        }, onError: (e) {
          print('Upload task error: $e');
        });

        // Wait for upload completion
        await uploadTask;
        print('Upload complete!');

        // Get the download URL
        final String downloadUrl = await storageRef.getDownloadURL();
        print('Download URL: $downloadUrl');
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ));
      }
    }

    print('Uploaded ${downloadUrls.length} images successfully');
    return downloadUrls;
  }

  // Function to save all emergency data to Firestore
  Future<void> _uploadEmergencyData({bool isFinalUpload = false}) async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        // Sign in anonymously if needed for emergency purposes
        await _auth.signInAnonymously();
        print("Signed in anonymously for emergency upload");
      }

      // Get current user ID (or anonymous ID)
      String userId = 'anonymous';
      if (_auth.currentUser != null) {
        userId = _auth.currentUser!.uid;
      }

      // Create base data map
      final Map<String, dynamic> caseData = {
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add basic data if this is first upload or final upload
      if (isFinalUpload) {
        // Add call end status for final upload
        caseData['status'] = 'completed';
        caseData['callEndedAt'] = FieldValue.serverTimestamp();
        caseData['callDurationSeconds'] = _callDurationInSeconds;

        // Add final case summary
        caseData['finalAssessment'] = _assessmentSummary;
        caseData['finalRecommendations'] = _recommendations;
      }

      // Upload images only if there are new ones to upload
      if (_identificationImages.isNotEmpty) {
        final List<String> idImageUrls =
            await _uploadImages(_identificationImages, 'id_images');
        caseData['victimDetails'] = {
          'nric': _nricController.text.trim(),
          'name': _nameController.text.trim(),
          'age': _ageController.text.isEmpty
              ? null
              : int.tryParse(_ageController.text.trim()),
          'idImages': idImageUrls,
        };
      } else if (_nricController.text.isNotEmpty ||
          _nameController.text.isNotEmpty ||
          _ageController.text.isNotEmpty) {
        // Only update text fields if images are empty but text fields have data
        caseData['victimDetails'] = {
          'nric': _nricController.text.trim(),
          'name': _nameController.text.trim(),
          'age': _ageController.text.isEmpty
              ? null
              : int.tryParse(_ageController.text.trim()),
        };
      }

      // Upload wound images if available
      if (_woundImages.isNotEmpty) {
        final List<String> woundImageUrls =
            await _uploadImages(_woundImages, 'wound_images');
        caseData['medicalDetails'] = {
          'woundImages': woundImageUrls,
          'assessment': _assessmentSummary,
          'recommendations': _recommendations,
        };
      }

      // Create transcript data for Firestore if this is first upload or final upload
      if (_transcript.isNotEmpty) {
        final List<Map<String, dynamic>> transcriptData = _transcript
            .map((item) => {
                  'speaker': item['speaker'],
                  'text': item['text'],
                  'isCritical': item['isCritical'],
                  'timestamp': DateTime.now().toIso8601String(),
                })
            .toList();

        caseData['transcript'] = transcriptData;
      }

      // First check if the document exists
      final docRef =
          _firestore.collection('case_SCDF_medical').doc(_emergencyCaseId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Document doesn't exist, create it with initial data
        await docRef.set({
          'caseId': _emergencyCaseId,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'emergencyType': 'Medical',
          'status': 'active',
          ...caseData
        });
      } else {
        // Document exists, update it
        await docRef.update(caseData);
      }

      // Clear uploaded images to prevent re-uploading
      if (_identificationImages.isNotEmpty) {
        _identificationImages.clear();
      }
      if (_woundImages.isNotEmpty) {
        _woundImages.clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isFinalUpload
              ? 'Emergency case completed and uploaded'
              : 'Emergency data updated successfully'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload emergency data: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _endCall() {
    // Use a simpler approach that doesn't store contexts across async boundaries
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('End Call?'),
        content: const Text('Are you sure you want to end the emergency call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Close the confirmation dialog first
              Navigator.of(dialogContext).pop();

              // Now handle the upload with a new dialog
              _handleEndCallAndUpload();
            },
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEndCallAndUpload() async {
    // Show the loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Uploading final case summary...')
          ],
        ),
      ),
    );

    try {
      // Upload final data
      await _uploadEmergencyData(isFinalUpload: true);

      // Dismiss loading dialog and get back to previous page
      if (mounted) {
        // Using Navigator.pop twice - first for the loading dialog, then for the page
        Navigator.of(context).pop(); // Close loading dialog

        // Add a small delay to ensure dialog is closed
        await Future.delayed(const Duration(milliseconds: 100));

        // Now navigate back to previous page
        if (mounted) {
          Navigator.of(context).pop(); // Go back to citizen_emergency.dart
        }
      }
    } catch (e) {
      // Handle error but still allow navigation
      if (mounted) {
        // Pop loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );

        // Still navigate back after a slight delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(); // Go back to citizen_emergency.dart
        }
      }
    }
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Medical Emergency',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: _endCall,
        ),
      ),
      body: _buildCallInterface(emergencyRed),
    );
  }

  Widget _buildCallInterface(Color primaryColor) {
    return Column(
      children: [
        // Call header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 5)
            ],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: primaryColor.withAlpha(76),
                                blurRadius: 10,
                                spreadRadius: 2)
                          ],
                        ),
                        child: Icon(Icons.phone_in_talk,
                            size: 24, color: primaryColor),
                      ),
                    );
                  }),
              Container(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Call (995)',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Call Duration: ${_formatDuration(_callDurationInSeconds)}',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.red.shade50),
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
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 3)
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(0, Icons.record_voice_over, "Call Logs"),
              ),
              Expanded(
                child: _buildTabButton(1, Icons.add_a_photo, "Upload Images"),
              ),
            ],
          ),
        ),

        // Page content
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: [
              _buildCallLogsView(),
              _buildImageUploadView(),
            ],
          ),
        ),

        // Recording button and action bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Column(
            children: [
              // New upload button
              if (_currentPageIndex ==
                  1) // Show upload button only on the images tab
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadEmergencyData,
                    icon: _isUploading
                        ? Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Upload Emergency Data',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: primaryColor.withOpacity(0.7),
                    ),
                  ),
                ),

              Row(
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
                                color: _isRecording
                                    ? Colors.green.shade100
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                _isRecording ? Icons.mic : Icons.mic_off,
                                color:
                                    _isRecording ? Colors.green : Colors.grey,
                              ),
                            ),
                          ),
                          Container(width: 8),
                          Expanded(
                            child: Text(
                              _isRecording
                                  ? "Recording... Speak clearly"
                                  : "Tap microphone to speak",
                              style: GoogleFonts.poppins(
                                color: _isRecording
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withAlpha(25),
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
                                    prefixIcon: Icon(Icons.perm_identity),
                                  ),
                                ),
                                Container(height: 16),
                                const Text(
                                    'This will help retrieve the victim\'s medical history'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'NRIC submitted successfully')));
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final bool isSelected = _currentPageIndex == index;
    return InkWell(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFEA4335) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFEA4335) : Colors.grey,
              size: 20,
            ),
            Container(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? const Color(0xFFEA4335) : Colors.grey,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallLogsView() {
    return Column(
      children: [
        // Transcript section
        Expanded(
          flex: 70,
          child: Container(
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat,
                            size: 18, color: Colors.black54),
                      ),
                      Container(width: 8),
                      Text("Call Transcript",
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                ),
              ],
            ),
          ),
        ),

        Container(height: 1, color: Colors.grey.shade300),

        // Assessment section
        Expanded(
          flex: 30,
          child: Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4481EB).withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assessment,
                          size: 18, color: Color(0xFF4481EB)),
                    ),
                    Container(width: 8),
                    Text("AI Assessment",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    _assessmentSummary,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
                Divider(color: Colors.grey.shade300),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lightbulb,
                          size: 18, color: Color(0xFFFF9800)),
                    ),
                    Container(width: 8),
                    Text("Recommended Actions",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
                Container(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("1. ",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Expanded(
                            child: Text(_recommendations[0],
                                style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                        ],
                      ),
                      Container(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("2. ",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Expanded(
                            child: Text(_recommendations[1],
                                style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadView() {
    return Column(
      children: [
        // Victim identification section
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4481EB).withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_pin,
                          size: 18, color: Color(0xFF4481EB)),
                    ),
                    Container(width: 8),
                    Text("Victim Identification",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    _identificationImages.isEmpty
                        ? ElevatedButton.icon(
                            onPressed: _pickIDImage,
                            icon: const Icon(Icons.add_a_photo, size: 14),
                            label: const Text("Add ID Photo"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4481EB),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0),
                              minimumSize: const Size(0, 30),
                            ),
                          )
                        : TextButton.icon(
                            onPressed: _pickIDImage,
                            icon: Icon(Icons.add_a_photo,
                                size: 14, color: Colors.grey.shade700),
                            label: Text("Add",
                                style: TextStyle(color: Colors.grey.shade700)),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 30),
                            ),
                          ),
                  ],
                ),
                Container(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_identificationImages.isNotEmpty)
                        Container(
                          width: 80,
                          height: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            image: DecorationImage(
                              image: FileImage(
                                  File(_identificationImages.last.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller: _nricController,
                              decoration: InputDecoration(
                                labelText: 'NRIC/ID',
                                labelStyle: GoogleFonts.poppins(
                                  color: const Color(0xFF4481EB),
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF4481EB), width: 2),
                                ),
                                prefixIcon: const Icon(Icons.perm_identity,
                                    color: Color(0xFF4481EB)),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            Container(height: 8),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: GoogleFonts.poppins(
                                  color: const Color(0xFF4481EB),
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF4481EB), width: 2),
                                ),
                                prefixIcon: const Icon(Icons.person,
                                    color: Color(0xFF4481EB)),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            Container(height: 8),
                            TextField(
                              controller: _ageController,
                              decoration: InputDecoration(
                                labelText: 'Age',
                                labelStyle: GoogleFonts.poppins(
                                  color: const Color(0xFF4481EB),
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF4481EB), width: 2),
                                ),
                                prefixIcon: const Icon(Icons.calendar_today,
                                    color: Color(0xFF4481EB)),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Container(height: 1, color: Colors.grey.shade300),

        // Wounds/symptoms section
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA4335).withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.healing,
                              size: 18, color: Color(0xFFEA4335)),
                        ),
                        Container(width: 8),
                        Text("Wounds & Symptoms",
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickWoundImage,
                      icon: const Icon(Icons.camera_alt, size: 14),
                      label: Text(
                        "Take Photo",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA4335),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        minimumSize: const Size(0, 30),
                      ),
                    ),
                  ],
                ),
                Container(height: 4),
                Text(
                  "Take clear photos of injuries to help emergency services",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
                Container(height: 8),
                Expanded(
                  child: _woundImages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 36, color: Colors.grey.shade400),
                              Container(height: 8),
                              Text("No wound images yet",
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _woundImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_woundImages[index].path),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _woundImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(127),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptBubble(String speaker, String text,
      {required bool isCritical}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: speaker == "Operator"
                ? const Color(0xFF4481EB).withAlpha(25)
                : const Color(0xFFEA4335).withAlpha(25),
            child: Icon(
              speaker == "Operator" ? Icons.headset_mic : Icons.person,
              size: 12,
              color: speaker == "Operator"
                  ? const Color(0xFF4481EB)
                  : const Color(0xFFEA4335),
            ),
          ),
          Container(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCritical
                        ? const Color(0xFFEA4335).withAlpha(12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
