import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'register_pages.dart';
import '../course/course_list_page.dart';
import '../../data/repositories/course_repository.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoggedIn;
  const LoginPage({super.key, this.onLoggedIn});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  bool showPassword = false;
  String? error;

  // Dynamic API base URL based on platform
  static String get apiBase {
    if (kIsWeb) {
      return 'http://localhost:5000';
    } else {
      return 'http://10.0.2.2:5000';
    }
  }

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      // User is already logged in, navigate to courses
      _navigateToCourses();
    }
  }

  void _navigateToCourses() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/courses',
      (route) => false,
    );
  }

  Future<void> _login() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBase/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailCtrl.text.trim(),
          'password': passCtrl.text,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        // Store token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        
        // Navigate to courses
        _navigateToCourses();
        
        // Call callback if provided
        widget.onLoggedIn?.call();
      } else {
        setState(() {
          error = data['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      print('Login error: $e');
      setState(() {
        error = 'Network error. Please check your connection.';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: passCtrl,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
              ),
              obscureText: !showPassword,
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : _login,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterPage(),
                  ),
                );
              },
              child: const Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
