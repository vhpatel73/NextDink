import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // Central Park coordinates as a default
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(40.7812, -73.9665),
    zoom: 14.4746,
  );

  final Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _loadMockCourts();
  }

  void _loadMockCourts() {
    setState(() {
      _markers.addAll([
        Marker(
          markerId: const MarkerId('court_1'),
          position: const LatLng(40.7812, -73.9665),
          infoWindow: const InfoWindow(title: 'Central Park Pickleball Courts'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () => _showBookingSheet('Central Park Pickleball Courts'),
        ),
        Marker(
          markerId: const MarkerId('court_2'),
          position: const LatLng(40.7850, -73.9600),
          infoWindow: const InfoWindow(title: 'East Side Rec Center'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () => _showBookingSheet('East Side Rec Center'),
        ),
        Marker(
          markerId: const MarkerId('court_3'),
          position: const LatLng(40.7750, -73.9750),
          infoWindow: const InfoWindow(title: 'West Side Tennis & Pickle'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () => _showBookingSheet('West Side Tennis & Pickle'),
        ),
      ]);
    });
  }

  void _showBookingSheet(String courtName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                courtName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '4 spots available • Open until 10:00 PM',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Scheduled game at $courtName!')),
                  );
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.black),
                label: const Text(
                  'Book a Game Here',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Court', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialPosition,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          // Normally we'd set dark mode styling string here for the map tiles
        },
      ),
    );
  }
}
