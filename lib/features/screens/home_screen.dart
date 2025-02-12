import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'location_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.example.findmyphone/device');

  String _deviceModel = "Loading...";
  String _deviceBattery = "Loading...";
  String _deviceChip = "Loading...";
  String _wifiStatus = "Loading..."; // Wi-Fi status instead of storage/IMEI

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  // Fetch device info including Wi-Fi status using MethodChannel
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
                  _infoRow(Icons.wifi,
                      "Wi-Fi: $_wifiStatus"), // Wi-Fi info instead of storage
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
    return Column(
      children: [
        _deviceTile(context, "JINGFEI's AirPods Pro", "Online", "120KM", "90%"),
        _deviceTile(context, "JINGFEI's Android X", "Offline", "90KM", "60%"),
      ],
    );
  }

  Widget _deviceTile(BuildContext context, String name, String status,
      String distance, String battery) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: Icon(
          status == "Online" ? Icons.wifi : Icons.wifi_off,
          color: status == "Online" ? Colors.green : Colors.red,
        ),
        title: Text(name),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LocationScreen()),
          );
        },
      ),
    );
  }
}
