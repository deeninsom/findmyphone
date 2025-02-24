import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'location_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const MethodChannel platform =
      MethodChannel('com.example.findmyphone/device');
  static const MethodChannel _platformNetwork =
      MethodChannel('com.example.findmyphone/network');
static const MethodChannel _channelDevice =
      MethodChannel('com.example.findmyphone/ANDROID_ID');
  String _deviceModel = "Loading...";
  String _deviceBattery = "Loading...";
  String _deviceChip = "Loading...";
  String _wifiStatus = "Loading...";
  String _networkStatus = "Checking...";
  String? _deviceId;

  List<dynamic> _devices = []; // List to store devices

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
    _getNetworkStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getDeviceId();
    });
    _fetchDevices(); // Fetch devices from API
  }

  /// Mendapatkan Device ID
  /// Fetch device info using MethodChannel
  Future<void> _getDeviceInfo() async {
    try {
      final Map<String, dynamic> deviceInfo = Map<String, dynamic>.from(
          await platform.invokeMethod('getDeviceInfo'));

      setState(() {
        _deviceModel = deviceInfo['model'] ?? 'Unknown model';
        _deviceBattery = '${deviceInfo['batteryLevel']}%' ?? 'Unknown battery';
        _deviceChip = deviceInfo['cpuArchitecture'] ?? 'Unknown chip';
        _wifiStatus = deviceInfo['wifiStatus'] ?? 'No Wi-Fi connection';
      });
    } on PlatformException catch (e) {
      print("Failed to get device info: '${e.message}'.");
    }
  }

  /// Get initial network status
  Future<void> _getNetworkStatus() async {
    try {
      final String status =
          await _platformNetwork.invokeMethod('getNetworkStatus');
      setState(() {
        _networkStatus = status.toString();
      });
    } on PlatformException catch (e) {
      print("Failed to get network status: '${e.message}'.");
    }
  }

  /// Get JWT Token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token'); // Adjust key as needed
  }

  /// Mendapatkan Device ID
 Future<void> _getDeviceId() async {
    try {
      final String deviceId = await _channelDevice.invokeMethod('getAndroidId');
      print("Device ID: $deviceId");

      setState(() {
        _deviceId = deviceId;
      });
    } on PlatformException catch (e) {
      print("Error getting Device ID: ${e.message}");
    }
  }

  /// Fetch devices from API
  Future<void> _fetchDevices() async {
    const String apiUrl = 'http://192.168.60.30:8080/api/v1/users';
    String? token = await _getToken();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        List<dynamic> filteredDevices = data['devices']
            .where((device) => device['deviceId'] != _deviceId)
            .toList();

        setState(() {
          _devices = filteredDevices;
        });
      } else {
        print("Failed to load devices: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching devices: $e");
    }
  }

  Future<void> _sendWakeUpRequest(String deviceId, String fcmToken) async {
    const String apiUrl = 'http://192.168.60.30:8080/api/v1/devices/wakeup';
    String? token = await _getToken();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'deviceId': deviceId,
      'fcmToken': fcmToken,
    });

    try {
      final response =
          await http.post(Uri.parse(apiUrl), headers: headers, body: body);
      if (response.statusCode == 201) {
        print("Wake-up signal sent successfully to $deviceId");
      } else {
        print("Failed to wake up device: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending wake-up request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage('assets/profile.png'),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Hi! JINGFEI",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _deviceInfoCard(),
              const SizedBox(height: 20),
              const Text(
                "Devices",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _deviceList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/android.png',
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.smartphone, "Model: $_deviceModel"),
                  _infoRow(Icons.battery_full, "Battery: $_deviceBattery"),
                  _infoRow(Icons.memory, "Chip: $_deviceChip"),
                  _infoRow(Icons.wifi, "Wi-Fi: $_wifiStatus"),
                  _infoRow(Icons.network_check, "Network: $_networkStatus"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceList(BuildContext context) {
    if (_devices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No devices found."),
        ),
      );
    }

    return Column(
      children: _devices.map<Widget>((device) {
        return _deviceTile(
          context,
          device['deviceId'] ?? 'Unknown',
          device['fcmToken'] ?? '',
          "Online",
          "Unknown",
          "N/A",
        );
      }).toList(),
    );
  }

  Widget _deviceTile(BuildContext context, String deviceId, String fcmToken,
      String status, String distance, String battery) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
          leading: Icon(
            status == "Online" ? Icons.wifi : Icons.wifi_off,
            color: status == "Online" ? Colors.green : Colors.red,
          ),
          title: Text("Device ID: $deviceId"),
          subtitle: Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.blue),
              Text(" $distance  "),
              const Icon(Icons.battery_charging_full,
                  size: 16, color: Colors.green),
              Text(" $battery"),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LocationScreen()))
              }
          // onTap: () => _sendWakeUpRequest(deviceId, fcmToken), // Perbaikan
          ),
    );
  }
}
