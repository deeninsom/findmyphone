import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashPermissionLocation extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded( 
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 100, color: Colors.red),
                    SizedBox(height: 20),
                    Text(
                      "Location Permission Required",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "This app requires access to your location.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0), 
              child: SizedBox(
                width: double.infinity, 
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                const platform = MethodChannel('com.example.findmyphone/service');
                final bool granted = await platform.invokeMethod('requestPermission', {"permission": "location"});
                
                Navigator.pop(context, granted);
              },
                  style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                  child: Text("Enable Location Permission", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}