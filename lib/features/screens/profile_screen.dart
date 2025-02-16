import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isMainDevice = true;
  String deviceId = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  // Load deviceId from SharedPreferences
  Future<void> _loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      deviceId = prefs.getString('deviceId') ?? 'Unknown Device';
    });
  }

  // Save deviceId to SharedPreferences
  // Future<void> _saveDeviceId(String deviceId) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('deviceId', deviceId);
  // }

  // Toggle main device status
  void _toggleMainDevice(bool value) {
    setState(() {
      isMainDevice = value;
    });
  }

  // Logout function - clear shared preferences
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();  // Clear all saved preferences
    Navigator.pushReplacementNamed(context, '/login'); // Navigate to login screen (adjust route as needed)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _accountInfoCard(),
            const SizedBox(height: 20),
            _deviceInfoCard(),
            const Spacer(),
            _logoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _accountInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/profile.png'),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("JINGFEI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text("jingfei@example.com", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Current Device", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Icon(Icons.smartphone, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.device_hub, "Model: Android 12"),
            _infoRow(Icons.battery_full, "Battery: 90%"),
            _infoRow(Icons.memory, "Chip: A15 Bionic"),
            _infoRow(Icons.storage, "Storage: 64GB/24GB"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Set as Main Device", style: TextStyle(fontSize: 16)),
                Switch(
                  value: isMainDevice,
                  onChanged: _toggleMainDevice,
                  activeColor: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text("Device ID: $deviceId", style: TextStyle(fontSize: 14, color: Colors.grey)),
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
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(width: 8), // Adds spacing between icon and text
            Text(
              "Logout",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
