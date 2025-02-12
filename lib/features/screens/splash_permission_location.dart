import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashPermissionLocation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 100, color: Colors.red),
            SizedBox(height: 20),
            Text("Location Permission Required", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () async {
                const platform = MethodChannel('com.example.findmyphone/service');
                final bool granted = await platform.invokeMethod('requestPermission', {"permission": "location"});
                
                Navigator.pop(context, granted);
              },
              child: Text("Enable Location Permission"),
            ),
          ],
        ),
      ),
    );
  }
}