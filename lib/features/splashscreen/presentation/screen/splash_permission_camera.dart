import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_permission_camera.dart';
// import 'screens/splash_location.dart';
import 'features/auth/presentation/pages/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('com.yourapp/permission_handler');

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    List<String> permissions = ["camera", "location", "storage"];
    
    for (String permission in permissions) {
      bool granted = await _checkPermission(permission);
      if (!granted) {
        _navigateToSplash(permission);
        return;
      }
    }

    _navigateToLogin();
  }

  Future<bool> _checkPermission(String permission) async {
    try {
      final bool granted = await platform.invokeMethod('checkPermission', {"permission": permission});
      return granted;
    } on PlatformException catch (e) {
      print("Failed to check permission: '${e.message}'.");
      return false;
    }
  }

  void _navigateToSplash(String permission) {
    Widget splashScreen;
    switch (permission) {
      case "camera":
        splashScreen = SplashPermissionCamera();
        break;
      // case "location":
      //   splashScreen = SplashLocationScreen();
      //   break;
      // case "storage":
      //   splashScreen = SplashStorageScreen();
      //   break;
      default:
        splashScreen = LoginScreen();
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => splashScreen));
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: CircularProgressIndicator()), // Loading sementara
      ),
    );
  }
}