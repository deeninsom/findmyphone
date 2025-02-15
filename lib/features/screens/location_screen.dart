import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'main_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  static const EventChannel _eventLocationChannel = EventChannel('com.example.findmyphone/location');

  LatLng? _currentPosition;
  bool _isLoading = true;
  final LatLng _destination = LatLng(-7.364879432981343, 112.72897518124178);  // Example destination coordinates

  late StreamSubscription _locationSubscription;  // To hold the subscription

  @override
  void initState() {
    super.initState();

    _getInitialLocation(); // Get initial location before listening for updates
    _startListeningLocation(); // Start listening for real-time location updates
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    _locationSubscription.cancel();
    super.dispose();
  }

  /// Get the initial location using MethodChannel
  Future<void> _getInitialLocation() async {
    var position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });
  }

  /// Listen for real-time location updates from the background service
  void _startListeningLocation() {
    _locationSubscription = _eventLocationChannel.receiveBroadcastStream().listen(
      (event) {
        if (!mounted) return;  // Ensure widget is still mounted
        print("Received location: $event");
        final double latitude = event['latitude'];
        final double longitude = event['longitude'];
        print("Live Location: Latitude: $latitude, Longitude: $longitude");
        setState(() {
          _currentPosition = LatLng(latitude, longitude);
          _isLoading = false;
        });
      },
      onError: (error) {
        print("Error receiving location updates: $error");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
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
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: _destination,
                          child: Icon(
                            Icons.my_location,
                            color: Colors.green,
                            size: 30.0,
                          ),
                        ),
                      ],
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _destination,
                          radius: 50.0,
                          useRadiusInMeter: true,
                          color: Colors.green.withOpacity(0.3),
                          borderColor: Colors.green,
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
              // onPressed: null,
              onPressed: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder : (context) => MainScreen() 
                  )
                )
              },
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
