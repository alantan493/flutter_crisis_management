import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CitizenPoliceEmergencyPage extends StatefulWidget {
  const CitizenPoliceEmergencyPage({super.key});

  @override
  State<CitizenPoliceEmergencyPage> createState() =>
      _CitizenPoliceEmergencyPageState();
}

class _CitizenPoliceEmergencyPageState extends State<CitizenPoliceEmergencyPage>
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _additionalInfoController =
      TextEditingController();

  // Image data
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _incidentImages = [];

  // Track uploaded images
  final Set<String> _uploadedIncidentImagePaths = {};
  bool _allImagesUploaded = false;

  // Mock data
  final List<Map<String, dynamic>> _transcript = [];
  final String _caseSummary =
      "ASSAULT REPORT\nLocation: 139A Lorong 1A Toa Payoh, Level 1, near lift lobby\nTime: 8:30pm\nSuspect description: Chinese male, thin build, approximately 30 years old, 180cm tall, wearing a hat, blue shirt and black jeans\nDirection of travel: Fled toward Block 142\nVictim is awaiting assistance at the scene";
  final List<String> _recommendations = [
    "Stay at a safe distance and observe. Do not intervene directly.",
    "Provide clear location details and describe the situation to operator."
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
      "text": "Police emergency line. What is your emergency?",
      "isCritical": false,
    });

    // Start call immediately
    _startCall();
  }

  @override
  void dispose() {
    _nricController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _additionalInfoController.dispose();
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

        // Simulate transcript updates for police scenarios
        if (_callDurationInSeconds == 3) {
          _addTranscriptMessage(
              "You",
              "Someone just assaulted me at 139A Lorong 1A Toa Payoh, Level 1, near the lift lobby.",
              true);
        } else if (_callDurationInSeconds == 8) {
          _addTranscriptMessage(
              "Operator",
              "Can you describe the person using this format? Race, Gender, Age, Height, Outfit",
              false);
        } else if (_callDurationInSeconds == 13) {
          _addTranscriptMessage(
              "You",
              "Skinny Chinese Male, Around 30 Years Old, 180cm, wearing a hat, blue shirt and black jeans. Ran away towards Block 142",
              true);
        } else if (_callDurationInSeconds == 18) {
          _addTranscriptMessage(
              "Operator",
              "Understood, police officers will be dispatched to apprehend the suspect. Can you fill in any additional information you can think of in the information page.",
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

  Future<void> _pickIncidentImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null && mounted) {
      setState(() {
        _incidentImages.add(image);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Incident photo added'),
          duration: Duration(seconds: 1)));
    }
  }

  // Improved function to upload images to Firebase Storage
  Future<List<String>> _uploadImages(List<XFile> images, String folder,
      {DocumentSnapshot? docSnapshot}) async {
    List<String> downloadUrls = [];

    if (images.isEmpty) {
      print('No images to upload');
      return downloadUrls;
    }

    // Filter out images that have already been uploaded
    final List<XFile> newImages = images.where((image) {
      return !_uploadedIncidentImagePaths.contains(image.path);
    }).toList();

    if (newImages.isEmpty) {
      print('No new images to upload');

      // Return existing URLs for already uploaded images if any
      if (docSnapshot != null && docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        final List<dynamic>? existingUrls = data?['incidentImages'];
        if (existingUrls != null) {
          return List<String>.from(existingUrls);
        }
      }

      return downloadUrls;
    }

    for (var image in newImages) {
      try {
        // Print image details for debugging
        print('Uploading image: ${image.path}');
        print('Image size: ${await File(image.path).length()} bytes');

        // Create a unique filename
        final String fileName =
            '${_emergencyCaseId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef =
            _storage.ref().child('case_SPF_police/$folder/$fileName');

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

        setState(() {
          _uploadedIncidentImagePaths.add(image.path);
        });
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ));
      }
    }

    // If we have existing URLs, merge them with new ones
    if (docSnapshot != null && docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>?;
      final List<dynamic>? existingUrls = data?['incidentImages'];
      if (existingUrls != null) {
        downloadUrls.addAll(List<String>.from(existingUrls));
      }
    }

    print(
        'Returned ${downloadUrls.length} URLs (${downloadUrls.length - newImages.length} existing, ${newImages.length} new)');
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

      // First check if the document exists - moved this up to use in _uploadImages
      final docRef =
          _firestore.collection('case_SPF_police').doc(_emergencyCaseId);
      final docSnapshot = await docRef.get();

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
        caseData['finalAssessment'] = _caseSummary;
        caseData['finalRecommendations'] = _recommendations;
      }

      // Add user information
      if (_nricController.text.isNotEmpty ||
          _nameController.text.isNotEmpty ||
          _phoneController.text.isNotEmpty) {
        caseData['reporterDetails'] = {
          'nric': _nricController.text.trim(),
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        };
      }

      // Add additional information if provided
      if (_additionalInfoController.text.isNotEmpty) {
        caseData['additionalInfo'] = _additionalInfoController.text.trim();
      }

      // Upload incident images if available
      if (_incidentImages.isNotEmpty) {
        final List<String> incidentImageUrls = await _uploadImages(
            _incidentImages, 'incident_images',
            docSnapshot: docSnapshot);
        caseData['incidentImages'] = incidentImageUrls;
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

      if (!docSnapshot.exists) {
        // Document doesn't exist, create it with initial data
        await docRef.set({
          'caseId': _emergencyCaseId,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'emergencyType': 'Police',
          'status': 'active',
          ...caseData
        });
      } else {
        // Document exists, update it
        await docRef.update(caseData);
      }

      // Check if all images are uploaded
      setState(() {
        _allImagesUploaded = _incidentImages
            .every((img) => _uploadedIncidentImagePaths.contains(img.path));
      });

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

      // NOW is when we clear the images - only when ending the call
      _incidentImages.clear();
      _uploadedIncidentImagePaths.clear();

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
    const policeBlue = Color(0xFF7B68EE);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Police Emergency',
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
      body: _buildCallInterface(policeBlue),
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
                      'Police Call (999)',
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
                child: _buildTabButton(1, Icons.info, "Information"),
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
              _buildInformationView(),
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
                  1) // Show upload button only on the information tab
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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Upload Police Report',
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
                      icon: Icon(Icons.location_on, color: primaryColor),
                      onPressed: () {
                        // Show location sharing dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Share Location'),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                    'Share your current location with police?'),
                                SizedBox(height: 16),
                                Text(
                                    'This will help officers reach you faster.'),
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
                                              'Location shared successfully')));
                                },
                                child: const Text('Share'),
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
              color: isSelected ? const Color(0xFF7B68EE) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF7B68EE) : Colors.grey,
                  size: 20,
                ),
                if (index == 1 &&
                    _incidentImages.isNotEmpty &&
                    !_allImagesUploaded)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  ),
                if (index == 1 && _allImagesUploaded)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            Container(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? const Color(0xFF7B68EE) : Colors.grey,
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
    return SingleChildScrollView(
      child: Column(
        children: [
          // Transcript section
          Container(
            height: MediaQuery.of(context).size.height *
                0.4, // 40% of screen height
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

          Container(height: 1, color: Colors.grey.shade300),

          // Assessment section
          Container(
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
                        color: const Color(0xFF7B68EE).withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assessment,
                          size: 18, color: Color(0xFF7B68EE)),
                    ),
                    Container(width: 8),
                    Text("AI Case Summary",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    _caseSummary,
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
                    Text("Safety Instructions",
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
                Container(height: 16), // Add bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationView() {
    // Calculate status values
    final bool hasImages = _incidentImages.isNotEmpty;
    final bool partiallyUploaded = hasImages &&
        _uploadedIncidentImagePaths.isNotEmpty &&
        !_allImagesUploaded;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload Status Banner
          if (hasImages)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 36,
              color: _allImagesUploaded
                  ? Colors.green.shade100
                  : partiallyUploaded
                      ? Colors.amber.shade100
                      : Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    _allImagesUploaded
                        ? Icons.check_circle
                        : partiallyUploaded
                            ? Icons.sync
                            : Icons.info_outline,
                    size: 16,
                    color: _allImagesUploaded
                        ? Colors.green
                        : partiallyUploaded
                            ? Colors.amber.shade800
                            : Colors.blue.shade800,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _allImagesUploaded
                        ? "All images uploaded successfully"
                        : partiallyUploaded
                            ? "Some images still need to be uploaded"
                            : "Images ready to upload",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _allImagesUploaded
                          ? Colors.green.shade800
                          : partiallyUploaded
                              ? Colors.amber.shade800
                              : Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),

          // Your Identification section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4481EB).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person,
                    size: 18, color: Color(0xFF4481EB)),
              ),
              Container(width: 8),
              Text("Your Identification",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _pickIncidentImage,
                icon: const Icon(Icons.add_a_photo, size: 14),
                label: const Text("Add ID Photo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4481EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(0, 30),
                ),
              ),
            ],
          ),
          Container(height: 16),

          // NRIC/ID Field
          TextField(
            controller: _nricController,
            decoration: InputDecoration(
              labelText: 'NRIC/ID',
              labelStyle: GoogleFonts.poppins(
                color: const Color(0xFF7B68EE),
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF7B68EE), width: 2),
              ),
              prefixIcon:
                  const Icon(Icons.perm_identity, color: Color(0xFF7B68EE)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          Container(height: 12),

          // Full Name Field
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'FULL NAME',
              labelStyle: GoogleFonts.poppins(
                color: const Color(0xFF7B68EE),
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF7B68EE), width: 2),
              ),
              prefixIcon: const Icon(Icons.person, color: Color(0xFF7B68EE)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          Container(height: 12),

          // Phone Number Field
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'PHONE NUMBER',
              labelStyle: GoogleFonts.poppins(
                color: const Color(0xFF7B68EE),
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF7B68EE), width: 2),
              ),
              prefixIcon: const Icon(Icons.phone, color: Color(0xFF7B68EE)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
            keyboardType: TextInputType.phone,
          ),
          Container(height: 24),

          // Additional Information section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA4335).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning,
                    size: 18, color: Color(0xFFEA4335)),
              ),
              Container(width: 8),
              Text("Additional Information",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _pickIncidentImage,
                icon: const Icon(Icons.camera_alt, size: 14),
                label: const Text("Take Photo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA4335),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(0, 30),
                ),
              ),
            ],
          ),
          Container(height: 8),

          Text(
            "of Current Case",
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Container(height: 8),

          Text(
            "Please provide any additional details about the suspect.\nFacial features, accent, distinctive marks, outfit, or unique characteristics.\nEvery detail helps our officers find them quickly.",
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
          Container(height: 12),

          // Additional info text field
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _additionalInfoController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: 'Enter Text Here',
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          Container(height: 16),

          Text(
            "Upload a photo of the incident location to help officers identify the exact scene.",
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
          Container(height: 12),

          // Image upload area
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: _incidentImages.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file,
                          size: 40, color: Colors.grey.shade400),
                      Container(height: 8),
                      Text(
                        "Upload your images here",
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _incidentImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_incidentImages[index].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Upload status indicator
                          if (_uploadedIncidentImagePaths
                              .contains(_incidentImages[index].path))
                            Positioned(
                              left: 4,
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(200),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _incidentImages.removeAt(index);
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
                ? const Color(0xFF7B68EE).withAlpha(25)
                : const Color(0xFF7B68EE).withAlpha(25),
            child: Icon(
              speaker == "Operator" ? Icons.headset_mic : Icons.person,
              size: 12,
              color: const Color(0xFF7B68EE),
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
                        ? const Color(0xFF7B68EE).withAlpha(12)
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
