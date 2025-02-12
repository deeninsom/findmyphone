import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/screens/splash_permission_camera.dart';
import 'features/screens/splash_permission_location.dart';
import 'features/screens/splash_permission_storage.dart';
import 'features/screens/splash_permission_battery.dart'; // Tambahkan layar baterai
import 'features/screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PermissionHandlerScreen(),
    );
  }
}

class PermissionHandlerScreen extends StatefulWidget {
  @override
  _PermissionHandlerScreenState createState() => _PermissionHandlerScreenState();
}

class _PermissionHandlerScreenState extends State<PermissionHandlerScreen> {
  static const platform = MethodChannel('com.example.findmyphone/service');
  List<String> pendingPermissions = [];
  bool batteryOptimized = true; // Default dianggap sudah diizinkan

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  /// Mengecek daftar izin yang belum diberikan dan status optimasi baterai
  Future<void> _checkPermissions() async {
    try {
      // Cek izin normal (kamera, lokasi, penyimpanan)
      final List<dynamic> permissions = await platform.invokeMethod('checkPermissions');
      pendingPermissions = List<String>.from(permissions);

      // Cek status optimasi baterai
      batteryOptimized = await platform.invokeMethod('isIgnoringBatteryOptimizations');

      debugPrint("Pending Permissions: $pendingPermissions");
      debugPrint("Battery Optimized: $batteryOptimized");

      _navigateToNextPermissionScreen();
    } on PlatformException catch (e) {
      debugPrint("Failed to check permissions: '${e.message}'.");
      _navigateToLogin();
    }
  }

  /// Navigasi ke splash screen izin yang belum diberikan
  void _navigateToNextPermissionScreen() async {
  if (!mounted) return;

  if (pendingPermissions.isEmpty && batteryOptimized) {
    debugPrint("All permissions granted. Navigating to login.");
    _navigateToLogin();
    return;
  }

  if (pendingPermissions.isNotEmpty) {
    String permission = pendingPermissions.removeAt(0);
    debugPrint("Navigating to permission screen for: $permission");

    Widget splashScreen;
    switch (permission) {
      case "camera":
        splashScreen = SplashPermissionCamera();
        break;
      case "location":
        splashScreen = SplashPermissionLocation();
        break;
      case "storage":
        splashScreen = SplashPermissionStorage();
        break;
      case "battery":
        splashScreen = SplashPermissionBattery();
        break;
      default:
        _navigateToLogin();
        return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => splashScreen),
    );

    if (mounted) {
      _checkPermissions();
    }
    return;
  }

  if (!batteryOptimized) {
    debugPrint("Navigating to battery optimization screen.");
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SplashPermissionBattery()),
    );

    if (mounted) {
      _checkPermissions();
    }
    return;
  }
}

  void _navigateToLogin() {
    if (!mounted) return;
    
    debugPrint("Navigating to Login Screen");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}