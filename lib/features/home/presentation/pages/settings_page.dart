import 'package:flutter/material.dart';
import 'dart:io'; // Untuk deteksi OS
import 'package:device_info_plus/device_info_plus.dart'; // Untuk informasi perangkat

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String deviceModel = "Unknown";
  String osVersion = "Unknown";
  bool isLocationEnabled = false;
  bool isNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        deviceModel = androidInfo.model;
        osVersion = "Android ${androidInfo.version.release}";
      });
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      setState(() {
        deviceModel = iosInfo.utsname.machine;
        osVersion = "iOS ${iosInfo.systemVersion}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Card untuk Informasi Akun
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: const Text("John Doe", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: const Text("johndoe@example.com"),
                trailing: const Icon(Icons.edit, color: Colors.blueAccent),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Edit Profile Clicked!")),
                  );
                },
              ),
            ),

            // Card untuk Informasi Perangkat
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.devices, color: Colors.green),
                title: Text("Device: $deviceModel", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                subtitle: Text("OS Version: $osVersion"),
              ),
            ),

            // Card untuk Permission Settings
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Enable Location"),
                    subtitle: const Text("Allow app to access your location"),
                    value: isLocationEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        isLocationEnabled = value;
                      });
                    },
                    secondary: Icon(Icons.location_on, color: isLocationEnabled ? Colors.blue : Colors.grey),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[300]),
                  SwitchListTile(
                    title: const Text("Enable Notifications"),
                    subtitle: const Text("Receive app notifications"),
                    value: isNotificationEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        isNotificationEnabled = value;
                      });
                    },
                    secondary: Icon(Icons.notifications, color: isNotificationEnabled ? Colors.blue : Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}