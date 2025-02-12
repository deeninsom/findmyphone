import 'package:flutter/material.dart';
import 'location_screen.dart';

class HomeScreen extends StatelessWidget {
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
              _deviceList(context), // 🔹 Kirim context ke _deviceList()
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
                  _infoRow(Icons.smartphone, "Model: Android 12"),
                  _infoRow(Icons.battery_full, "Battery: 90%"),
                  _infoRow(Icons.memory, "Chip: A15 Bionic"),
                  _infoRow(Icons.storage, "Storage: 64GB/24GB"),
                  _infoRow(Icons.confirmation_number, "IMEI: 35-673874-7 385273-2"),
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

  Widget _deviceList(BuildContext context) { // 🔹 Tambahkan parameter context
    return Column(
      children: [
        _deviceTile(context, "JINGFEI's AirPods Pro", "Online", "120KM", "90%"),
        _deviceTile(context, "JINGFEI's Android X", "Offline", "90KM", "60%"),
      ],
    );
  }

  Widget _deviceTile(BuildContext context, String name, String status, String distance, String battery) {
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
            const Icon(Icons.battery_charging_full, size: 16, color: Colors.green),
            Text(" $battery"),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // 🔹 Navigasi ke LocationScreen saat diklik
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LocationScreen()),
          );
        },
      ),
    );
  }
}
