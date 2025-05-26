import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

// API Key Service
class ApiKeyService {
  static const platform = MethodChannel('api_keys');
  static String? _cachedApiKey;
  
  static Future<String> getGoogleMapsApiKey() async {
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey!;
    }
    
    try {
      final String apiKey = await platform.invokeMethod('getGoogleMapsApiKey');
      _cachedApiKey = apiKey;
      return apiKey;
    } on PlatformException catch (e) {
      print("Failed to get API key: '${e.message}'");
      return '';
    } catch (e) {
      print("Unexpected error getting API key: $e");
      return '';
    }
  }
}

// Data models
enum SafetyPlaceType {
  police,
  hospital,
  fireStation,
  aed,
}

class SafetyLocation {
  final String id;
  final String name;
  final LatLng location;
  final SafetyPlaceType type;
  final double distanceKm;
  final double? rating;
  final bool? isOpen;
  final String address;
  final String? phoneNumber;
  
  SafetyLocation({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.distanceKm,
    this.rating,
    this.isOpen,
    required this.address,
    this.phoneNumber,
  });
  
  String get typeDisplayName {
    switch (type) {
      case SafetyPlaceType.police:
        return 'Police Station';
      case SafetyPlaceType.hospital:
        return 'Hospital';
      case SafetyPlaceType.fireStation:
        return 'Fire Station';
      case SafetyPlaceType.aed:
        return 'AED Location';
    }
  }
  
  IconData get typeIcon {
    switch (type) {
      case SafetyPlaceType.police:
        return Icons.local_police;
      case SafetyPlaceType.hospital:
        return Icons.local_hospital;
      case SafetyPlaceType.fireStation:
        return Icons.local_fire_department;
      case SafetyPlaceType.aed:
        return Icons.medical_services;
    }
  }
  
  Color get typeColor {
    switch (type) {
      case SafetyPlaceType.police:
        return const Color(0xFF1565C0); // Dark blue
      case SafetyPlaceType.hospital:
        return const Color(0xFFD32F2F); // Red
      case SafetyPlaceType.fireStation:
        return const Color(0xFFFF6F00); // Orange
      case SafetyPlaceType.aed:
        return const Color(0xFF388E3C); // Green
    }
  }
  
  Color get typeBackgroundColor {
    switch (type) {
      case SafetyPlaceType.police:
        return const Color(0xFFE3F2FD);
      case SafetyPlaceType.hospital:
        return const Color(0xFFFFEBEE);
      case SafetyPlaceType.fireStation:
        return const Color(0xFFFFF3E0);
      case SafetyPlaceType.aed:
        return const Color(0xFFE8F5E9);
    }
  }
  
  String get distanceText {
    if (distanceKm < 0.1) {
      return '${(distanceKm * 1000).round()} m away';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km away';
    }
  }
}

// Places Service
class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  static Future<List<SafetyLocation>> getNearbyPlaces({
    required LatLng location,
    double radiusKm = 1.0,
  }) async {
    // Get API key from local.properties
    final apiKey = await ApiKeyService.getGoogleMapsApiKey();
    
    if (apiKey.isEmpty) {
      print('No API key available, using fallback data');
      return _getFallbackData(location);
    }

    final List<SafetyLocation> allPlaces = [];
    final radiusMeters = (radiusKm * 1000).round();

    try {
      // Search for each type of safety location
      final searchQueries = [
        {'type': 'police', 'safetyType': SafetyPlaceType.police},
        {'type': 'hospital', 'safetyType': SafetyPlaceType.hospital},
        {'type': 'fire_station', 'safetyType': SafetyPlaceType.fireStation},
      ];

      // Search for standard place types
      for (final query in searchQueries) {
        try {
          final places = await _searchByType(
            location: location,
            type: query['type'] as String,
            radiusMeters: radiusMeters,
            safetyType: query['safetyType'] as SafetyPlaceType,
            apiKey: apiKey,
          );
          allPlaces.addAll(places);
        } catch (e) {
          print('Error searching for ${query['type']}: $e');
        }
      }

      // Search for AEDs using keyword search
      try {
        final aeds = await _searchByKeyword(
          location: location,
          keyword: 'AED defibrillator',
          radiusMeters: radiusMeters,
          apiKey: apiKey,
        );
        allPlaces.addAll(aeds);
      } catch (e) {
        print('Error searching for AEDs: $e');
      }

      // Sort by distance
      allPlaces.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      
      return allPlaces;
    } catch (e) {
      print('Error in getNearbyPlaces: $e');
      // Return fallback mock data if API fails
      return _getFallbackData(location);
    }
  }

  static Future<List<SafetyLocation>> _searchByType({
    required LatLng location,
    required String type,
    required int radiusMeters,
    required SafetyPlaceType safetyType,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/nearbysearch/json?'
      'location=${location.latitude},${location.longitude}&'
      'radius=$radiusMeters&'
      'type=$type&'
      'key=$apiKey'
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
        final List<SafetyLocation> places = [];
        
        if (data['results'] != null) {
          for (final place in data['results']) {
            try {
              final lat = place['geometry']['location']['lat']?.toDouble();
              final lng = place['geometry']['location']['lng']?.toDouble();
              
              if (lat != null && lng != null) {
                final placeLocation = LatLng(lat, lng);
                final distance = _calculateDistance(location, placeLocation);
                
                places.add(SafetyLocation(
                  id: place['place_id'] ?? '',
                  name: place['name'] ?? 'Unknown',
                  location: placeLocation,
                  type: safetyType,
                  distanceKm: distance,
                  rating: place['rating']?.toDouble(),
                  isOpen: place['opening_hours']?['open_now'],
                  address: place['vicinity'] ?? place['formatted_address'] ?? '',
                ));
              }
            } catch (e) {
              print('Error parsing place: $e');
              continue;
            }
          }
        }
        
        return places;
      } else {
        throw Exception('Places API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
      }
    } else {
      throw Exception('HTTP error: ${response.statusCode}');
    }
  }

  static Future<List<SafetyLocation>> _searchByKeyword({
    required LatLng location,
    required String keyword,
    required int radiusMeters,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/nearbysearch/json?'
      'location=${location.latitude},${location.longitude}&'
      'radius=$radiusMeters&'
      'keyword=$keyword&'
      'key=$apiKey'
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
        final List<SafetyLocation> places = [];
        
        if (data['results'] != null) {
          for (final place in data['results']) {
            try {
              final lat = place['geometry']['location']['lat']?.toDouble();
              final lng = place['geometry']['location']['lng']?.toDouble();
              
              if (lat != null && lng != null) {
                final placeLocation = LatLng(lat, lng);
                final distance = _calculateDistance(location, placeLocation);
                
                places.add(SafetyLocation(
                  id: place['place_id'] ?? '',
                  name: place['name'] ?? 'Unknown AED',
                  location: placeLocation,
                  type: SafetyPlaceType.aed,
                  distanceKm: distance,
                  rating: place['rating']?.toDouble(),
                  isOpen: place['opening_hours']?['open_now'],
                  address: place['vicinity'] ?? place['formatted_address'] ?? '',
                ));
              }
            } catch (e) {
              print('Error parsing AED place: $e');
              continue;
            }
          }
        }
        
        return places;
      } else {
        throw Exception('Places API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
      }
    } else {
      throw Exception('HTTP error: ${response.statusCode}');
    }
  }

  // Fallback mock data if API fails
  static List<SafetyLocation> _getFallbackData(LatLng location) {
    return [
      SafetyLocation(
        id: 'fallback_police',
        name: 'Nearby Police Station',
        location: LatLng(location.latitude + 0.001, location.longitude + 0.001),
        type: SafetyPlaceType.police,
        distanceKm: 0.2,
        address: 'Police Station (Offline Mode)',
      ),
      SafetyLocation(
        id: 'fallback_hospital',
        name: 'Nearby Hospital',
        location: LatLng(location.latitude - 0.001, location.longitude + 0.001),
        type: SafetyPlaceType.hospital,
        distanceKm: 0.3,
        address: 'Hospital (Offline Mode)',
      ),
    ];
  }
  
  // Calculate distance between two points using Haversine formula
  static double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _toRadians(end.latitude - start.latitude);
    final dLng = _toRadians(end.longitude - start.longitude);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(start.latitude)) *
            math.cos(_toRadians(end.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

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
  bool _isLoadingPlaces = false;
  
  // Current location (can be real GPS or simulated)
  final LatLng _currentLocation = const LatLng(1.2834, 103.8607); // Marina Bay Sands as default
  
  // Dynamic places data
  List<SafetyLocation> _nearbyPlaces = [];
  final Set<Marker> _markers = {};
  
  // Filter states
  final Map<SafetyPlaceType, bool> _activeFilters = {
    SafetyPlaceType.police: true,
    SafetyPlaceType.hospital: true,
    SafetyPlaceType.fireStation: true,
    SafetyPlaceType.aed: true,
  };

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
    
    _initializeCurrentLocationMarker();
    _loadNearbyPlaces();
  }

  void _initializeCurrentLocationMarker() {
    // Remove any existing current location marker first
    _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
    
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose), // Dark pink/magenta
        infoWindow: const InfoWindow(
          title: 'YOU ARE HERE',
          snippet: 'Your current location',
        ),
      ),
    );
    
    // Auto-show the info window for current location
    Future.delayed(const Duration(milliseconds: 500), () {
      _mapController?.showMarkerInfoWindow(const MarkerId('current_location'));
    });
    
    // Trigger a rebuild to show the updated marker
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadNearbyPlaces() async {
    setState(() {
      _isLoadingPlaces = true;
    });

    try {
      final places = await PlacesService.getNearbyPlaces(
        location: _currentLocation,
        radiusKm: 1.0, // 1km radius
      );
      
      setState(() {
        _nearbyPlaces = places;
        _isLoadingPlaces = false;
      });
      
      // Update markers after places are loaded
      _updateMapMarkers();
      
      // Show the current location info window after a delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        _mapController?.showMarkerInfoWindow(const MarkerId('current_location'));
      });
    } catch (e) {
      setState(() {
        _isLoadingPlaces = false;
      });
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load nearby places: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateMapMarkers() {
    // Clear all markers except current location
    _markers.removeWhere((marker) => marker.markerId.value != 'current_location');
    
    // Add markers for filtered places with distinct colors
    for (final place in _nearbyPlaces) {
      if (_activeFilters[place.type] == true) {
        BitmapDescriptor icon;
        
        // Use distinct Google Maps marker colors for each type
        switch (place.type) {
          case SafetyPlaceType.police:
            icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
            break;
          case SafetyPlaceType.hospital:
            icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
            break;
          case SafetyPlaceType.fireStation:
            icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
            break;
          case SafetyPlaceType.aed:
            icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
            break;
        }
        
        _markers.add(
          Marker(
            markerId: MarkerId(place.id),
            position: place.location,
            icon: icon,
            infoWindow: InfoWindow(
              title: place.name,
              snippet: '${place.distanceText} • ${place.typeDisplayName}',
              onTap: () => _showPlaceDetails(place),
            ),
          ),
        );
      }
    }
    
    setState(() {});
  }

  void _showPlaceDetails(SafetyLocation place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: place.typeBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    place.typeIcon,
                    color: place.typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        place.typeDisplayName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.address,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions_walk, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  place.distanceText,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                if (place.rating != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.star, size: 16, color: Colors.amber[600]),
                  const SizedBox(width: 4),
                  Text(
                    place.rating!.toStringAsFixed(1),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Open directions
                      Navigator.pop(context);
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(place.location, 18.0),
                      );
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: place.typeColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (place.phoneNumber != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Make phone call
                        // You can use url_launcher package for this
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startLocationSimulation() {
    if (_isSimulating) return;
    
    setState(() {
      _isSimulating = true;
    });
    
    // Reinitialize the current location marker to ensure it shows correctly
    _initializeCurrentLocationMarker();
    
    // Animate camera to current location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation, 16.0),
    );
    
    // Reload places for current location
    _loadNearbyPlaces();
  }

  void _stopLocationSimulation() {
    setState(() {
      _isSimulating = false;
    });
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingPlaces ? null : _loadNearbyPlaces,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation,
                      zoom: 16.0,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      // Show current location info window once map is ready
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        controller.showMarkerInfoWindow(const MarkerId('current_location'));
                      });
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
                  
                  if (_isLoadingPlaces)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                ],
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                          "${_nearbyPlaces.length} safety locations nearby",
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
          Text(
            "Map Legend",
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Your location legend item
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.purple.shade800, // Dark purple for "YOU ARE HERE"
                                  size: 28,
                                ),
                                Positioned(
                                  top: 6,
                                  child: Icon(
                                    Icons.person_pin,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "YOU ARE HERE",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    const SizedBox(width: 100), // Spacer for alignment
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildLegendItem(
                      SafetyPlaceType.police,
                      Icons.local_police,
                      const Color(0xFF1565C0),
                      'Police',
                    ),
                    const SizedBox(width: 24),
                    _buildLegendItem(
                      SafetyPlaceType.hospital,
                      Icons.local_hospital,
                      const Color(0xFFD32F2F),
                      'Hospital',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildLegendItem(
                      SafetyPlaceType.fireStation,
                      Icons.local_fire_department,
                      const Color(0xFFFF6F00),
                      'Fire Station',
                    ),
                    const SizedBox(width: 24),
                    _buildLegendItem(
                      SafetyPlaceType.aed,
                      Icons.medical_services,
                      const Color(0xFF388E3C),
                      'AED',
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

  Widget _buildLegendItem(SafetyPlaceType type, IconData icon, Color color, String label) {
    return Expanded(
      child: Row(
        children: [
          // Legend shows pin icon to match what appears on map
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pin shape background
                Icon(
                  Icons.location_on,
                  color: color,
                  size: 28,
                ),
                // Small icon overlay
                Positioned(
                  top: 6,
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
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
          
          if (_isLoadingPlaces)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_nearbyPlaces.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No safety locations found nearby",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadNearbyPlaces,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_nearbyPlaces.take(5).map((place) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNearbyLocationCard(place),
            ))),
          
          if (_nearbyPlaces.length > 5)
            const SizedBox(height: 12),
          
          if (_nearbyPlaces.length > 5)
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "View All ${_nearbyPlaces.length} Safety Locations",
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

  Widget _buildNearbyLocationCard(SafetyLocation place) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPlaceDetails(place),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: place.typeBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    place.typeIcon,
                    color: place.typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            place.distanceText,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (place.isOpen != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: place.isOpen! ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                place.isOpen! ? 'Open' : 'Closed',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: place.typeBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions,
                    color: place.typeColor,
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