import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashPermissionCamera extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text("Camera Permission Required", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "This app requires access to your camera to capture images.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                const platform = MethodChannel('com.example.findmyphone/service');
                final bool granted = await platform.invokeMethod('requestPermission', {"permission": "camera"});
                
                Navigator.pop(context, granted); // Kembali ke MyApp
              },
              child: Text("Enable Camera Permission"),
            ),
          ],
        ),
      ),
    );
  }
}