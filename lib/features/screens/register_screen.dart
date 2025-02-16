import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  static const MethodChannel _channel =
      MethodChannel('com.example.findmyphone/fcm');
  String? _fcmToken;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    // _checkLoginStatus();
    _getFcmToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getDeviceId();
    });
  }

  Future<void> _register() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage("Nama, email, dan password tidak boleh kosong.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    const String apiUrl = "http://192.168.60.30:8080/api/v1/auth/register";
    final requestBody = {
      "username": name,
      "email": email,
      "password": password,
      "fcmToken": _fcmToken,
      "deviceId": _deviceId ?? "",
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);
      print("test : $responseData");
      if (response.statusCode == 201) {
        String token = responseData['accessToken'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        _showMessage("Registrasi berhasil!");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        _handleError(responseData);
      }
    } catch (e) {
      _showMessage("Terjadi kesalahan: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Mendapatkan FCM Token dari Native Android
  Future<void> _getFcmToken() async {
    try {
      final String? token = await _channel.invokeMethod('getFCMToken');
      if (token != null) {
        setState(() {
          _fcmToken = token;
        });
      }
    } catch (e) {
      print("Error getting FCM token: $e");
    }
  }

  /// Mendapatkan Device ID
  Future<void> _getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (Theme.of(context).platform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Android ID
      } else {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? "Unknown"; 
      }

      print("$deviceId");
      setState(() {
        _deviceId = deviceId;
      });
    } catch (e) {
      print("Error getting Device ID: $e");
    }
  }

  void _handleError(Map<String, dynamic> responseData) {
    if (responseData.containsKey("message")) {
      if (responseData["message"] is List) {
        _showMessage(
            responseData["message"].join(", ")); // Menggabungkan list error
      } else {
        _showMessage(responseData["message"].toString());
      }
    } else {
      _showMessage("Registrasi gagal, coba lagi.");
    }
  }

  /// Menampilkan Snackbar
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool _isPasswordVisible = false;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/objects.png',
            fit: BoxFit.cover,
          ),
          Column(
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'assets/icon-app.png', // Replace with your actual logo asset
                height: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                "Register here",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Create an account so you can explore all your\ndevice",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Username",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                  color: Color(0xFF4882E4),
                                  width: 2.0), // Warna saat fokus
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                  color: Color(0xFF4882E4),
                                  width: 2.0), // Warna saat fokus
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        StatefulBuilder(
                          builder: (context, setState) {
                            return TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: "Password",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                      color: Color(0xFF4882E4),
                                      width: 2.0), // Warna saat fokus
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Color(0xFF4882E4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              // setState(() {
                              //   _isLoading = true;
                              // });
                              // _register().then((_) {
                              //   setState(() {
                              //     _isLoading = false;
                              //   });
                              // });
                              _register();
                            },
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("Sign up",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          },
                          child: const Text("Alredy have an account",
                              style: TextStyle(color: Colors.black54)),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  
}
