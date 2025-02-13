import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  static const EventChannel _locationChannel =
      EventChannel('com.example.findmyphone/location');
  LatLng? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getInitialLocation(); // Get initial location before listening for updates
    _startListeningLocation(); // Start listening for real-time location updates
  }

  /// Get the initial location using Geolocator
  Future<void> _getInitialLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      print("Error getting initial location: $e");
    }
  }

  /// Listen for real-time location updates from the background service
  void _startListeningLocation() {
    _locationChannel.receiveBroadcastStream().listen((event) {
      print("Received location: $event"); // Check what data you're receiving
      if (event != null &&
          event['latitude'] != null &&
          event['longitude'] != null) {
        setState(() {
          _currentPosition = LatLng(event['latitude'], event['longitude']);
        });
      }
    }, onError: (error) {
      print("Error receiving location updates: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentPosition!,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: _currentPosition!,
                          child: Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 30.0,
                          ),
                        ),
                      ],
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _currentPosition!,
                          radius: 50.0,
                          useRadiusInMeter: true,
                          color: Colors.blue.withOpacity(0.3),
                          borderColor: Colors.blue,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  ],
                ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _bottomCard(),
          ),
        ],
      ),
    );
  }

  Widget _bottomCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Current Location",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _currentPosition == null
                ? const Text("Fetching location...")
                : Text(
                    "Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}\n"
                    "Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}",
                    style: const TextStyle(fontSize: 16),
                  ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.my_location),
              label: const Text("Location updates are received automatically."),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}