import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
// ignore: deprecated_member_use
import 'dart:js' as js;
import '../services/firestore_service.dart';

class MapScreen extends StatefulWidget {
  final bool pickingMode;
  const MapScreen({super.key, this.pickingMode = false});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(40.7812, -73.9665),
    zoom: 14.4746,
  );

  final Set<Marker> _markers = {};

  bool get _isLocalhost {
    if (!kIsWeb) return false;
    final host = Uri.base.host;
    return host == 'localhost' || host == '127.0.0.1';
  }

  @override
  void initState() {
    super.initState();
    if (!_isLocalhost) {
      _loadMockCourts();
    }
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
                onPressed: () async {
                  if (widget.pickingMode) {
                    Navigator.pop(context);
                    Navigator.pop(context, courtName);
                    return;
                  }
                  final scheduledTime = DateTime.now()
                      .add(const Duration(days: 1))
                      .copyWith(hour: 17, minute: 0, second: 0);
                  await FirestoreService().bookGame(courtName, scheduledTime);
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Scheduled game at $courtName!')),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.black),
                label: Text(
                  widget.pickingMode ? 'Select this Court' : 'Book a Game Here',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4F82B),
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
      body: _isLocalhost
          ? _buildLocalhostFallback(context)
          : kIsWeb
              ? _WebPlacesPicker(pickingMode: widget.pickingMode)
              : GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                ),
    );
  }

  Widget _buildLocalhostFallback(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map, size: 80, color: Color(0xFFD4F82B)),
          const SizedBox(height: 24),
          const Text('Map Picker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Use the text field in the wizard\nto enter court name on localhost.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _showBookingSheet('Localhost Test Court'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4F82B),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Simulate Selecting a Court',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Web-only Places Autocomplete picker — no full map rendering needed.
class _WebPlacesPicker extends StatefulWidget {
  final bool pickingMode;
  const _WebPlacesPicker({required this.pickingMode});

  @override
  State<_WebPlacesPicker> createState() => _WebPlacesPickerState();
}

class _WebPlacesPickerState extends State<_WebPlacesPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _loadingNearby = true;
  String? _selectedPlace;
  List<String> _nearbyCourts = [];

  // Debounce timer for search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchNearbyCourts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Request browser geolocation, then call the JS bridge for nearby courts
  void _fetchNearbyCourts() {
    try {
      js.context['navigator']['geolocation'].callMethod('getCurrentPosition', [
        js.allowInterop((position) {
          final lat = (position['coords']['latitude'] as num).toDouble();
          final lng = (position['coords']['longitude'] as num).toDouble();
          js.context.callMethod('_nearbyPickleballCourts', [
            lat,
            lng,
            js.allowInterop((js.JsArray results) {
              if (!mounted) return;
              setState(() {
                _nearbyCourts = results.map((r) => r.toString()).toList();
                _loadingNearby = false;
              });
            }),
          ]);
        }),
        js.allowInterop((_) {
          // Permission denied or error — clear loading
          if (mounted) setState(() => _loadingNearby = false);
        }),
      ]);
    } catch (_) {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  /// Call Places AutocompleteService via JS bridge with debounce
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _suggestions = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () {
      try {
        js.context.callMethod('_placesSearch', [
          value,
          js.allowInterop((js.JsArray results) {
            if (!mounted) return;
            final places = results.map((r) => r.toString()).toList();
            setState(() {
              _suggestions = places.isNotEmpty ? places : ['Use "$value" as location name'];
              _isSearching = false;
            });
          }),
        ]);
      } catch (_) {
        // Fallback if JS bridge not ready yet
        if (mounted) setState(() { _suggestions = ['Use "$value" as location name']; _isSearching = false; });
      }
    });
  }

  void _selectSuggestion(String suggestion) {
    final isFreeText = suggestion.startsWith('Use "') && suggestion.endsWith('" as location name');
    final location = isFreeText
        ? suggestion.replaceFirst('Use "', '').replaceAll('" as location name', '')
        : suggestion;
    setState(() {
      _selectedPlace = location;
      _searchController.text = location;
      _suggestions = [];
    });
  }

  void _confirmSelection() {
    if (_selectedPlace != null && _selectedPlace!.isNotEmpty) {
      if (widget.pickingMode) {
        Navigator.pop(context, _selectedPlace);
      } else {
        final scheduledTime = DateTime.now()
            .add(const Duration(days: 1))
            .copyWith(hour: 17, minute: 0, second: 0);
        FirestoreService().bookGame(_selectedPlace!, scheduledTime);
        Navigator.pop(context);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final neon = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Box
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: neon.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(color: neon.withOpacity(0.1), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search for a pickleball court or address...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: _isSearching
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: neon),
                              ),
                            )
                          : Icon(Icons.search, color: neon),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white38),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),

                const SizedBox(height: 12),

                // Autocomplete suggestions
                if (_suggestions.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: _suggestions.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        final isFreeText = s.startsWith('Use "');
                        return Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                isFreeText ? Icons.edit_location_alt : Icons.location_on,
                                color: isFreeText ? Colors.white38 : neon,
                                size: 20,
                              ),
                              title: Text(s, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              onTap: () => _selectSuggestion(s),
                            ),
                            if (i < _suggestions.length - 1)
                              const Divider(height: 1, color: Colors.white10),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                // Nearby courts list (shown when search box is empty)
                if (_suggestions.isEmpty && _searchController.text.isEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.near_me, color: neon, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _loadingNearby ? 'Finding courts near you...' : 'Courts Near You',
                        style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.0),
                      ),
                      if (_loadingNearby) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 10, height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: neon),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_loadingNearby)
                    ..._nearbyCourts.map((court) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => _selectSuggestion(court),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sports_tennis_rounded, color: neon, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(court, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                            ],
                          ),
                        ),
                      ),
                    )),
                  if (!_loadingNearby && _nearbyCourts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'No nearby courts found. Try searching above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                ],

                const Spacer(),

                // Confirm button
                if (_selectedPlace != null)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: neon.withOpacity(0.35), blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _confirmSelection,
                      icon: const Icon(Icons.check_circle_outline, color: Colors.black),
                      label: Text(
                        'Select "${_selectedPlace!}"',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neon,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
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
