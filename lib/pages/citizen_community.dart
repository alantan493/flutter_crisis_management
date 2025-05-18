import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CitizenCommunityPage extends StatefulWidget {
  const CitizenCommunityPage({super.key});

  @override
  State<CitizenCommunityPage> createState() => _CitizenCommunityPageState();
}

class _CitizenCommunityPageState extends State<CitizenCommunityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          'Community',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF0F4FF),
              radius: 18,
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sleek Tab Bar with properly rounded indicator
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Material(
              color: Colors.transparent,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[800],
                indicatorSize: TabBarIndicatorSize.tab,
                padding: const EdgeInsets.all(3),
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5575E7), Color(0xFF4481EB)],
                  ),
                  borderRadius: BorderRadius.circular(19),
                ),
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, 
                  fontSize: 14
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500, 
                  fontSize: 14
                ),
                tabs: const [
                  Tab(text: 'Feed', height: 38),
                  Tab(text: 'Events', height: 38),
                  Tab(text: 'Groups', height: 38)
                ],
              ),
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildFeedTab(), _buildEventsTab(), _buildGroupsTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF4481EB),
        elevation: 3,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
  
  Widget _buildFeedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildPost(
          username: 'Sarah Johnson',
          timeAgo: '2h ago',
          content: 'Just spotted a suspicious person looking into cars on Maple Street. Be alert everyone!',
          likes: 15,
          comments: 7,
          isAlert: true,
        ),
        _buildPost(
          username: 'Neighborhood Watch',
          timeAgo: '5h ago',
          content: 'Community clean-up event this Saturday at 10 AM. Meet at the park. Bring gloves!',
          likes: 32,
          comments: 12,
        ),
        _buildPost(
          username: 'Mike Peterson',
          timeAgo: '1d ago',
          content: 'Lost dog spotted near Oak Avenue. Small terrier with red collar. Currently at the shelter.',
          likes: 24,
          comments: 8,
          hasImage: true,
        ),
        _buildPost(
          username: 'Community Safety',
          timeAgo: '2d ago',
          content: 'New traffic lights will be installed next week at the Main St. intersection. Expect delays.',
          likes: 45,
          comments: 16,
        ),
      ],
    );
  }
  
  Widget _buildEventsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildEvent(
          title: 'Community Safety Workshop',
          date: 'May 25, 2025',
          time: '6:00 PM - 8:00 PM',
          location: 'Community Center',
          attendees: 34,
        ),
        _buildEvent(
          title: 'Neighborhood Watch Meeting',
          date: 'June 2, 2025',
          time: '7:00 PM - 8:30 PM',
          location: 'Public Library',
          attendees: 18,
        ),
        _buildEvent(
          title: 'First Aid Training',
          date: 'June 15, 2025',
          time: '10:00 AM - 2:00 PM',
          location: 'Fire Station',
          attendees: 27,
        ),
        _buildEvent(
          title: 'Community Emergency Drill',
          date: 'June 28, 2025',
          time: '9:00 AM - 11:00 AM',
          location: 'Central Park',
          attendees: 45,
        ),
      ],
    );
  }
  
  Widget _buildGroupsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildGroup(
          name: 'Neighborhood Watch',
          members: 124,
          description: 'Volunteers keeping our neighborhood safe',
        ),
        _buildGroup(
          name: 'Emergency Response Team',
          members: 56,
          description: 'Trained volunteers for emergency situations',
        ),
        _buildGroup(
          name: 'Community Parents',
          members: 213,
          description: 'Keeping our children safe in the community',
        ),
        _buildGroup(
          name: 'Safety Awareness',
          members: 87,
          description: 'Sharing safety tips and information',
        ),
      ],
    );
  }
  
  Widget _buildPost({
    required String username,
    required String timeAgo,
    required String content,
    required int likes,
    required int comments,
    bool isAlert = false,
    bool hasImage = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)],
        border: isAlert ? Border.all(color: const Color(0xFFEA4335), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // User Avatar
                CircleAvatar(
                  backgroundColor: const Color(0xFFF0F4FF),
                  radius: 20,
                  child: Text(username[0], 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4481EB))),
                ),
                const SizedBox(width: 10),
                // Username & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(timeAgo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                // Alert Badge
                if (isAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFEA4335), Color(0xFFFF5252)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 3),
                        const Text('ALERT', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
          // Image (if present)
          if (hasImage)
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 180,
              width: double.infinity,
              color: const Color(0xFFF0F4FF),
              child: Icon(Icons.photo, size: 40, color: Colors.grey[400]),
            ),
          // Actions Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Like Button
                _buildActionButton(Icons.thumb_up_outlined, likes.toString(), const Color(0xFF4481EB)),
                const SizedBox(width: 16),
                // Comment Button
                _buildActionButton(Icons.chat_bubble_outline, comments.toString(), Colors.grey[700]!),
                const Spacer(),
                // Reply Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.reply, size: 14, color: Color(0xFF4481EB)),
                      SizedBox(width: 4),
                      Text('Reply', 
                        style: TextStyle(
                          color: Color(0xFF4481EB), 
                          fontSize: 12, 
                          fontWeight: FontWeight.w500
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
  
  Widget _buildEvent({
    required String title,
    required String date,
    required String time,
    required String location,
    required int attendees,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Header
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(colors: [Color(0xFF5575E7), Color(0xFF4481EB)]),
            ),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          // Event Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventItem(Icons.calendar_today, date),
                const SizedBox(height: 8),
                _buildEventItem(Icons.access_time, time),
                const SizedBox(height: 8),
                _buildEventItem(Icons.location_on, location),
                const SizedBox(height: 8),
                _buildEventItem(Icons.people, '$attendees attending'),
                const SizedBox(height: 16),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      // Details Button
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4481EB),
                        side: const BorderSide(color: Color(0xFF4481EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    // Attend Button
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF4481EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text('Attend', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF4481EB)),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
  
  Widget _buildGroup({
    required String name,
    required int members,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.group_rounded, size: 24, color: Color(0xFF4481EB)),
            ),
            const SizedBox(width: 12),
            // Group Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('$members members', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 13, height: 1.3)),
                  const SizedBox(height: 12),
                  // Join Button
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF4481EB),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Join', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Row(
                children: [
                  const Text('Create Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Text Field
              TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'What\'s happening in your community?',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4481EB), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  // Camera Button
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt, size: 20, color: Color(0xFF4481EB)),
                  ),
                  const SizedBox(width: 12),
                  // Alert Button
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFEA4335)),
                  ),
                  const Spacer(),
                  // Post Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Post created successfully!', 
                            style: TextStyle(color: Colors.white)),
                          backgroundColor: Color(0xFF4481EB),
                          behavior: SnackBarBehavior.fixed,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF4481EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Post', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}