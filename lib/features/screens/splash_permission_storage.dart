import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashPermissionStorage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sd_storage, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text("Storage Permission Required", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () async {
                const platform = MethodChannel('com.example.findmyphone/service');
                final bool granted = await platform.invokeMethod('requestPermission', {"permission": "storage"});
                
                Navigator.pop(context, granted);
              },
              child: Text("Enable Storage Permission"),
            ),
          ],
        ),
      ),
    );
  }
}