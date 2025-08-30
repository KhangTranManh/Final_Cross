import 'package:flutter/material.dart';
import 'auth/login_pages.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage(
              onLoggedIn: () {
                // Handle login success
              },
            )),
          ),
          child: const Text('Login'),
        ),
      ),
    );
  }
}
