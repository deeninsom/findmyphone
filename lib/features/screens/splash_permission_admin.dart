import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashPermissionAdmin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded( // Bagian konten akan menyesuaikan
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.battery_alert, size: 100, color: Colors.blue),
                    SizedBox(height: 20),
                    Text(
                      "Allow admin permission.",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "This app requires Device Admin permission for security features. Please enable it this permission.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0), // Jarak dari bawah & samping
              child: SizedBox(
                width: double.infinity, // Membuat tombol full width
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                debugPrint("Requesting battery optimization...");
                const platform = MethodChannel('com.example.findmyphone/service');
                try {
                  final bool granted = await platform.invokeMethod('requestAdminPermission');
                  debugPrint("Admin permission granted: $granted");
                  if (granted) {
                    Navigator.pop(context, true);
                  }
                } on PlatformException catch (e) {
                  debugPrint("Failed to request battery optimization: ${e.message}");
                  Navigator.pop(context, true);
                }
              },
                  style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                  child: Text("Enable Admin Permission", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}