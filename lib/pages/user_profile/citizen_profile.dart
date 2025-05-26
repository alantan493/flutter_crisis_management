import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import '../../services/account_database.dart';

class CitizenProfilePage extends StatefulWidget {
  const CitizenProfilePage({super.key});

  @override
  State<CitizenProfilePage> createState() => _CitizenProfilePageState();
}

class _CitizenProfilePageState extends State<CitizenProfilePage> with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  // Settings data (these would typically be stored separately)
  bool _notificationsEnabled = true;
  bool _locationSharingEnabled = true;
  bool _darkModeEnabled = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _databaseService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      _logger.e('Error loading profile: $e');
      setState(() {
        _userProfile = null;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.edit_outlined, color: Color(0xFF4481EB), size: 20),
            ),
            onPressed: () => _showEditProfileDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4481EB),
              ),
            )
          : _userProfile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Profile not found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4481EB),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildProfileHeader()),
                      SliverToBoxAdapter(child: _buildPersonalInfoCard()),
                      SliverToBoxAdapter(child: _buildEmergencyContactCard()),
                      SliverToBoxAdapter(child: _buildSettingsCard()),
                      SliverToBoxAdapter(child: _buildAccountActionsCard()),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final String name = _userProfile?['displayName'] ?? 'No Name';
    final String initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('');
    final String email = _userProfile?['email'] ?? 'No Email';
    final String joinDate = _userProfile?['createdAt'] != null 
        ? _formatJoinDate(_userProfile!['createdAt']) 
        : 'Unknown';
    
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'profileAvatar',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5575E7), Color(0xFF4481EB)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4481EB).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _userProfile?['profileImageUrl'] != null
                  ? CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(_userProfile!['profileImageUrl']),
                    )
                  : CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: Text(
                        initials,
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4481EB),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Member since $joinDate',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF4481EB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF4481EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Personal Information",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoItem(
              Icons.cake_outlined,
              'Age',
              _userProfile?['age']?.toString() ?? 'Not set',
            ),
            _buildInfoItem(
              Icons.calendar_today_outlined,
              'Joined',
              _userProfile?['createdAt'] != null 
                  ? _formatFullDate(_userProfile!['createdAt'])
                  : 'Unknown date',
            ),
            _buildInfoItem(
              Icons.email_outlined,
              'Email',
              _userProfile?['email'] ?? 'Not set',
            ),
            _buildInfoItem(
              Icons.phone_outlined,
              'Phone',
              _userProfile?['phone'] ?? 'Not set',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emergency_outlined,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Emergency Contact",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoItem(
              Icons.contact_emergency_outlined,
              'Contact Name',
              _userProfile?['emergencyContactName'] ?? 'Not set',
            ),
            _buildInfoItem(
              Icons.phone_in_talk_outlined,
              'Contact Phone',
              _userProfile?['emergencyContactPhone'] ?? 'Not set',
            ),
            _buildInfoItem(
              Icons.people_outline,
              'Relationship',
              _userProfile?['emergencyContactRelationship'] ?? 'Not set',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF5575E7)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF4481EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Settings",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSwitchItem('Enable Notifications', _notificationsEnabled, (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            }),
            _buildSwitchItem('Share Location', _locationSharingEnabled, (value) {
              setState(() {
                _locationSharingEnabled = value;
              });
            }),
            _buildSwitchItem('Dark Mode', _darkModeEnabled, (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4481EB),
            activeTrackColor: const Color(0xFF4481EB).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_circle_outlined,
                    color: Color(0xFF4481EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Account",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildActionItem(
              Icons.refresh_outlined,
              'Refresh Profile',
              const Color(0xFF10B981),
              _loadUserProfile,
            ),
            _buildActionItem(
              Icons.help_outline_rounded,
              'Help & Support',
              const Color(0xFF6E5DE7),
              () {
                // Navigate to help and support
              },
            ),
            _buildActionItem(
              Icons.privacy_tip_outlined,
              'Privacy Settings',
              const Color(0xFF5575E7),
              () {
                // Navigate to privacy settings
              },
            ),
            _buildActionItem(
              Icons.logout_rounded,
              'Sign Out',
              Colors.red.shade400,
              () {
                // Sign out functionality
                Navigator.pushReplacementNamed(context, '/login');
              },
              textColor: Colors.red.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color iconColor, VoidCallback onTap, {Color? textColor}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: textColor ?? const Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final displayNameController = TextEditingController(
      text: _userProfile?['displayName'] ?? '',
    );
    final ageController = TextEditingController(
      text: _userProfile?['age']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: _userProfile?['phone'] ?? '',
    );
    final emergencyNameController = TextEditingController(
      text: _userProfile?['emergencyContactName'] ?? '',
    );
    final emergencyPhoneController = TextEditingController(
      text: _userProfile?['emergencyContactPhone'] ?? '',
    );
    final emergencyRelationshipController = TextEditingController(
      text: _userProfile?['emergencyContactRelationship'] ?? '',
    );
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF4481EB),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Edit Profile',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Display Name Field
                        TextFormField(
                          controller: displayNameController,
                          decoration: InputDecoration(
                            labelText: 'Display Name',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                            ),
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF4481EB)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4481EB), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          style: GoogleFonts.poppins(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your display name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Age Field
                        TextFormField(
                          controller: ageController,
                          decoration: InputDecoration(
                            labelText: 'Age',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                            ),
                            prefixIcon: const Icon(Icons.cake_outlined, color: Color(0xFF4481EB)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4481EB), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          style: GoogleFonts.poppins(),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final age = int.tryParse(value);
                              if (age == null) {
                                return 'Please enter a valid age';
                              }
                              if (age < 1 || age > 120) {
                                return 'Please enter a reasonable age';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone Field
                        TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                            ),
                            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF4481EB)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4481EB), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          style: GoogleFonts.poppins(),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        
                        // Emergency Contact Section Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.emergency_outlined,
                                color: Colors.red.shade600,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Emergency Contact',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Emergency Contact Name
                        TextFormField(
                          controller: emergencyNameController,
                          decoration: InputDecoration(
                            labelText: 'Emergency Contact Name',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                            ),
                            prefixIcon: const Icon(Icons.contact_emergency_outlined, color: Color(0xFF4481EB)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4481EB), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(height: 16),
                        
                        // Emergency Contact Phone
                        TextFormField(
                          controller: emergencyPhoneController,
                          decoration: InputDecoration(
                            labelText: 'Emergency Contact Phone',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                            ),
                            prefixIcon: const Icon(Icons.phone_in_talk_outlined, color: Color(0xFF4481EB)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4481EB), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          style: GoogleFonts.poppins(),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        
                        // Emergency Contact Relationship
                        TextFormField(
                          controller: emergencyRelationshipController,
                          decoration: InputDecoration(
                            labelText: 'Relationship to Emergency Contact',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                            ),
                            prefixIcon: const Icon(Icons.people_outline, color: Color(0xFF4481EB)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4481EB), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          style: GoogleFonts.poppins(),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 24),
                        
                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isLoading ? null : () {
                                Navigator.of(dialogContext).pop();
                              },
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: isLoading ? null : () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  setDialogState(() {
                                    isLoading = true;
                                  });

                                  try {
                                    final int? age = ageController.text.isNotEmpty
                                        ? int.tryParse(ageController.text)
                                        : null;

                                    // First update the basic profile info
                                    await _databaseService.updateUserProfile(
                                      displayName: displayNameController.text.trim(),
                                      age: age,
                                    );
                                    
                                    // Then update the additional fields using the generic update method
                                    final Map<String, dynamic> additionalUpdates = {};
                                    if (phoneController.text.trim().isNotEmpty) {
                                      additionalUpdates['phone'] = phoneController.text.trim();
                                    }
                                    if (emergencyNameController.text.trim().isNotEmpty) {
                                      additionalUpdates['emergencyContactName'] = emergencyNameController.text.trim();
                                    }
                                    if (emergencyPhoneController.text.trim().isNotEmpty) {
                                      additionalUpdates['emergencyContactPhone'] = emergencyPhoneController.text.trim();
                                    }
                                    if (emergencyRelationshipController.text.trim().isNotEmpty) {
                                      additionalUpdates['emergencyContactRelationship'] = emergencyRelationshipController.text.trim();
                                    }
                                    
                                    // Update additional fields if there are any
                                    if (additionalUpdates.isNotEmpty) {
                                      await _databaseService.updateUserData(additionalUpdates);
                                    }

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.white),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Profile updated successfully!',
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.green.shade700,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                      Navigator.of(dialogContext).pop();
                                      // Reload the profile data
                                      _loadUserProfile();
                                    }
                                  } catch (e) {
                                    _logger.e('Error updating profile: $e');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.error_outline, color: Colors.white),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'Error updating profile: ${e.toString()}',
                                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.red.shade700,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setDialogState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4481EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Save Changes',
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
            );
          },
        );
      },
    );
  }

  String _formatJoinDate(String createdAt) {
    try {
      final DateTime date = DateTime.parse(createdAt);
      final List<String> months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatFullDate(String createdAt) {
    try {
      final DateTime date = DateTime.parse(createdAt);
      final List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}