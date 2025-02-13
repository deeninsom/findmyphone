import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashPermissionStorage extends StatelessWidget {
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
                    Icon(Icons.sd_storage, size: 100, color: Colors.green),
                    SizedBox(height: 20),
                    Text(
                      "Storage Permission Required",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "This app requires access to your storage.",
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
                const platform = MethodChannel('com.example.findmyphone/service');
                final bool granted = await platform.invokeMethod('requestPermission', {"permission": "storage"});
                
                Navigator.pop(context, granted);
              },
                  style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                  child: Text("Enable Storage Permission", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}