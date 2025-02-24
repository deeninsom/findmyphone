import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'register_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  static const MethodChannel _channel =
      MethodChannel('com.example.findmyphone/fcm');
      static const MethodChannel _channelDevice =
      MethodChannel('com.example.findmyphone/ANDROID_ID');
  String? _fcmToken;
  String? _deviceId;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _getFcmToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getDeviceId();
    });
  }

  /// Mengecek apakah pengguna sudah login
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
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
      final String deviceId = await _channelDevice.invokeMethod('getAndroidId');
      print("Device ID: $deviceId");

      setState(() {
        _deviceId = deviceId;
      });
    } on PlatformException catch (e) {
      print("Error getting Device ID: ${e.message}");
    }
  }

  /// Fungsi untuk login ke API NestJS
  Future<void> _login() async {
    print("$_fcmToken");
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Email dan password tidak boleh kosong.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    const String apiUrl = "http://192.168.60.30:8080/api/v1/auth/login";
    print("FCM Token: $_fcmToken, Device ID: $_deviceId");

    final requestBody = {
      "email": email,
      "password": password,
      "fcmToken": _fcmToken,
      "deviceId": "$_deviceId",
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        String token = responseData['accessToken'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('device_id', _deviceId ?? "Unknown");

        _showMessage("Login berhasil!");

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

   void _handleError(Map<String, dynamic> responseData) {
    if (responseData.containsKey("message")) {
      if (responseData["message"] is List) {
        _showMessage(
            responseData["message"].join(", "));
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
                'assets/icon-app.png',
                height: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                "Login here",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Welcome back you've\nbeen missed!",
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
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                  color: Color(0xFF4882E4),
                                  width: 2.0),
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
                                      width: 2.0),
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
                              setState(() {
                                _isLoading = true;
                              });
                              _login().then((_) {
                                setState(() {
                                  _isLoading = false;
                                });
                              });
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
                                : const Text("Sign in",
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
                                  builder: (context) => RegisterScreen()),
                            );
                          },
                          child: const Text("Create new account",
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
