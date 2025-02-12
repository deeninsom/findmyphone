import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashPermissionBattery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.battery_alert, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              "Allow Battery Optimization",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "To ensure the app runs properly in the background, please allow battery optimization.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                debugPrint("Requesting battery optimization...");
                const platform = MethodChannel('com.example.findmyphone/service');
                try {
                  final bool granted = await platform.invokeMethod('requestBatteryOptimization');
                  debugPrint("Battery optimization granted: $granted");
                  if (granted) {
                    Navigator.pop(context, true);
                  }
                } on PlatformException catch (e) {
                  debugPrint("Failed to request battery optimization: ${e.message}");
                }
              },
              child: Text("Enable Battery Optimization"),
            ),
          ],
        ),
      ),
    );
  }
}