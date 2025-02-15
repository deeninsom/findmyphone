import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/screens/main_screen.dart';
import 'features/screens/login_screen.dart';
import 'features/screens/splash_permission_camera.dart';
import 'features/screens/splash_permission_location.dart';
import 'features/screens/splash_permission_storage.dart';
import 'features/screens/splash_permission_battery.dart';
import 'features/screens/splash_permission_admin.dart';

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
  _PermissionHandlerScreenState createState() =>
      _PermissionHandlerScreenState();
}

class _PermissionHandlerScreenState extends State<PermissionHandlerScreen> {
  static const platform = MethodChannel('com.example.findmyphone/service');
  List<String> pendingPermissions = [];
  bool batteryOptimized = true;
  bool adminPermission = true;
  String? jwtToken; // Variabel untuk menyimpan token JWT

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTokenAndPermissions();
    });
  }

  /// Cek apakah ada token JWT yang tersimpan
  Future<void> _checkTokenAndPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    jwtToken = prefs.getString("jwt_token");

    if (jwtToken != null && jwtToken!.isNotEmpty) {
      debugPrint("JWT Token found: Navigating to MainScreen");
      _navigateToMain();
    } else {
      debugPrint("No JWT Token found. Checking permissions...");
      _checkPermissions();
    }
  }

  /// Mengecek daftar izin yang belum diberikan dan status optimasi baterai
  Future<void> _checkPermissions() async {
    try {
      final List<dynamic> permissions =
          await platform.invokeMethod('checkPermissions');
      pendingPermissions = List<String>.from(permissions);

      batteryOptimized =
          await platform.invokeMethod('isIgnoringBatteryOptimizations');

      adminPermission =
          await platform.invokeMethod('isIgnoringAdminPermission');

      debugPrint("Pending Permissions: $pendingPermissions");
      debugPrint("Battery Optimized: $batteryOptimized");
      debugPrint("Is Device Admin Active: $adminPermission");

      _navigateToNextPermissionScreen();
    } on PlatformException catch (e) {
      debugPrint("Failed to check permissions: '${e.message}'.");
      _navigateToLogin();
    }
  }

  /// Navigasi ke splash screen izin yang belum diberikan
  void _navigateToNextPermissionScreen() async {
    if (!mounted) return;

    if (pendingPermissions.isEmpty && batteryOptimized && adminPermission) {
      debugPrint("All permissions granted. Navigating to login or main.");
      jwtToken != null ? _navigateToMain() : _navigateToLogin();
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
        default:
          _navigateToLogin();
          return;
      }

      if (!batteryOptimized) {
        debugPrint("Navigating to battery optimization screen.");
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SplashPermissionBattery()),
        );
        if (mounted) _checkPermissions();
        return;
      }

      if (!adminPermission) {
        debugPrint("Navigating to admin permission screen.");
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SplashPermissionAdmin()),
        );
        if (mounted) _checkPermissions();
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => splashScreen),
      );

      if (mounted) _checkPermissions();
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

  void _navigateToMain() {
    if (!mounted) return;

    debugPrint("Navigating to Main Screen");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
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