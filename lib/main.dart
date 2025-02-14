import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/screens/splash_permission_camera.dart';
import 'features/screens/splash_permission_location.dart';
import 'features/screens/splash_permission_storage.dart';
import 'features/screens/splash_permission_battery.dart';
import 'features/screens/splash_permission_admin.dart';
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
  _PermissionHandlerScreenState createState() =>
      _PermissionHandlerScreenState();
}

class _PermissionHandlerScreenState extends State<PermissionHandlerScreen> {
  static const platform = MethodChannel('com.example.findmyphone/service');
  List<String> pendingPermissions = [];
  bool batteryOptimized = true; // Default dianggap sudah diizinkan
  bool adminPermission = true;

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
      final List<dynamic> permissions =
          await platform.invokeMethod('checkPermissions');
      pendingPermissions = List<String>.from(permissions);

      // Cek status optimasi baterai
      batteryOptimized =
          await platform.invokeMethod('isIgnoringBatteryOptimizations');

      // Cek apakah izin admin perangkat diberikan
      adminPermission =
          await platform.invokeMethod('isIgnoringAdminPermission');

      debugPrint("Pending Permissions: $pendingPermissions");
      debugPrint("Battery Optimized: $batteryOptimized");
      debugPrint("Is Device Admin Active: $adminPermission");

      // Panggil metode untuk menavigasi ke izin atau login
      _navigateToNextPermissionScreen();
    } on PlatformException catch (e) {
      debugPrint("Failed to check permissions: '${e.message}'.");
      _navigateToLogin();
    }
  }

  /// Navigasi ke splash screen izin yang belum diberikan
  void _navigateToNextPermissionScreen() async {
    if (!mounted) return;

    // Cek apakah semua izin sudah diberikan dan optimasi baterai sudah diizinkan
    if (pendingPermissions.isEmpty && batteryOptimized && adminPermission) {
      debugPrint("All permissions granted. Navigating to login.");
      _navigateToLogin();
      return;
    }

    // Jika ada izin yang tertunda, tangani satu per satu
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

      // Jika optimasi baterai belum diizinkan, navigasi ke layar optimasi baterai
      if (!batteryOptimized) {
        debugPrint("Navigating to battery optimization screen.");
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SplashPermissionBattery()),
        );

        // Periksa izin setelah kembali dari layar optimasi baterai
        if (mounted) {
          _checkPermissions(); // Recheck after navigating to the battery screen
        }
        return;
      }

      // Jika izin admin belum diberikan, navigasi ke layar izin admin
      if (!adminPermission) {
        debugPrint("Navigating to admin optimization screen.");
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SplashPermissionAdmin()),
        );

        // Periksa izin setelah kembali dari layar admin
        if (mounted) {
          _checkPermissions(); // Recheck after navigating to the admin screen
        }
        return;
      }

      // Jika sudah semua izin diberikan, lanjutkan ke layar izin yang diminta
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => splashScreen),
      );

      // Setelah kembali, periksa izin kembali
      if (mounted) {
        _checkPermissions(); // Recheck permissions after handling this one
      }
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
      body: Center(child: CircularProgressIndicator()), // Menampilkan loading spinner sementara
    );
  }
}
