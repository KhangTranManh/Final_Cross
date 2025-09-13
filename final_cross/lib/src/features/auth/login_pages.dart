import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    // Check if user is already logged in with Firebase Auth
    final user = _auth.currentUser;
    if (user != null) {
      _navigateToCourses();
    }
  }

  void _navigateToCourses() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/courses', // Make sure this matches your route
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
      // Use Firebase Auth instead of HTTP request
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );

      if (credential.user != null) {
        // Get Firebase ID token and store it - handle null safety
        final token = await credential.user!.getIdToken();
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
        }
        
        // Navigate to courses
        _navigateToCourses();
        
        // Call callback if provided
        widget.onLoggedIn?.call();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            error = 'No user found with this email.';
            break;
          case 'wrong-password':
            error = 'Wrong password provided.';
            break;
          case 'invalid-email':
            error = 'Invalid email address.';
            break;
          case 'user-disabled':
            error = 'This account has been disabled.';
            break;
          default:
            error = e.message ?? 'Login failed';
        }
      });
    } catch (e) {
      print('Login error: $e');
      setState(() {
        error = 'An unexpected error occurred.';
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
