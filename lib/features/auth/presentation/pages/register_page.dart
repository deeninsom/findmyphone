import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Register",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _usernameController,
                hintText: "Username",
                icon: Icons.person,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _emailController,
                hintText: "Email",
                icon: Icons.email,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _passwordController,
                hintText: "Password",
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement register logic
                  Navigator.pop(context);
                },
                child: Text("Register"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}