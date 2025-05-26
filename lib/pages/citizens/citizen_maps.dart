import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class CitizenMapsPage extends StatefulWidget {
  const CitizenMapsPage({super.key});

  @override
  State<CitizenMapsPage> createState() => _CitizenMapsPageState();
}

class _CitizenMapsPageState extends State<CitizenMapsPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Google Maps & Location Variables
  GoogleMapController? _mapController;
  Timer? _locationTimer;
  bool _isSimulating = false;
  int _currentLocationIndex = 0;
  
  // Marina Bay Sands single point simulation
  final LatLng _marinaBaySands = LatLng(1.2834, 103.8607); // Marina Bay Sands main entrance
  
  // Current simulated location
  LatLng _currentLocation = LatLng(1.2834, 103.8607); // Marina Bay Sands
  
  // Map markers
  Set<Marker> _markers = {};

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
    _animationController.forward();
    
    _initializeMarkers();
  }

  void _initializeMarkers() {
    _markers = {
      Marker(
        markerId: MarkerId('current_location'),
        position: _currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: 'Marina Bay Sands Area',
        ),
      ),
      // Safety locations around Marina Bay Sands
      Marker(
        markerId: MarkerId('police_station'),
        position: LatLng(1.2810, 103.8590),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Marina Bay Police Post',
          snippet: '0.3 km away',
        ),
      ),
      Marker(
        markerId: MarkerId('hospital'),
        position: LatLng(1.2800, 103.8550),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Raffles Hospital',
          snippet: '0.8 km away',
        ),
      ),
    };
  }

  void _startLocationSimulation() {
    if (_isSimulating) return;
    
    setState(() {
      _isSimulating = true;
      _currentLocation = _marinaBaySands;
      _updateCurrentLocationMarker();
    });
    
    // Animate camera to Marina Bay Sands
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_marinaBaySands, 16.0),
    );
  }

  void _stopLocationSimulation() {
    _locationTimer?.cancel();
    setState(() {
      _isSimulating = false;
    });
  }

  void _updateCurrentLocationMarker() {
    _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
    _markers.add(
      Marker(
        markerId: MarkerId('current_location'),
        position: _currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: 'Marina Bay Sands Area',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: Text(
          'Safety Map',
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
            icon: Icon(
              _isSimulating ? Icons.stop : Icons.play_arrow,
              color: _isSimulating ? Colors.red : Colors.green,
            ),
            onPressed: _isSimulating ? _stopLocationSimulation : _startLocationSimulation,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeaderSection()),
            SliverToBoxAdapter(child: _buildMapView()),
            SliverToBoxAdapter(child: _buildMapCategories()),
            SliverToBoxAdapter(child: _buildNearbyLocations()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Community Safety Map",
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  "View safety information and navigate your community",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
              ),
              if (_isSimulating)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "GPS Active",
                    style: GoogleFonts.poppins(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search places...",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          
          // Real Google Map Container
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: 16.0,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                markers: _markers,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                compassEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                zoomGesturesEnabled: true,
              ),
            ),
          ),
          
          // Map status bar with current location info
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.green[700],
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Current Location",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Marina Bay Sands, Singapore",
                          style: GoogleFonts.poppins(
                            color: Colors.green[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentLocation, 18.0),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Center",
                      style: GoogleFonts.poppins(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Map Layers",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildMapCategoryChip("Safety Alerts", Icons.warning_amber_rounded, const Color(0xFFE7863D), true),
                _buildMapCategoryChip("Police Stations", Icons.local_police_outlined, const Color(0xFF4481EB), false),
                _buildMapCategoryChip("Hospitals", Icons.local_hospital_outlined, const Color(0xFFE91E63), false),
                _buildMapCategoryChip("Fire Stations", Icons.fire_extinguisher, const Color(0xFFFF5722), false),
                _buildMapCategoryChip("Safe Shelters", Icons.home_outlined, const Color(0xFF4CAF50), false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCategoryChip(String label, IconData icon, Color color, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.transparent : color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.grey[800],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyLocations() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Nearby Safety Locations",
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildNearbyLocationCard(
            "Marina Bay Police Post",
            "0.3 km away",
            Icons.local_police_outlined,
            const Color(0xFF4481EB),
          ),
          const SizedBox(height: 12),
          _buildNearbyLocationCard(
            "Raffles Hospital",
            "0.8 km away",
            Icons.local_hospital_outlined,
            const Color(0xFFE91E63),
          ),
          const SizedBox(height: 12),
          _buildNearbyLocationCard(
            "Marina Bay Fire Station",
            "1.2 km away",
            Icons.fire_extinguisher,
            const Color(0xFFFF5722),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "View All Safety Locations",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4481EB),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyLocationCard(String title, String distance, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        distance,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions,
                    color: color,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}