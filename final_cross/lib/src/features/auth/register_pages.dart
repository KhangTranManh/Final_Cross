import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? error;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _register() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'Email and password are required');
      return;
    }

    if (password.length < 6) {
      setState(() => error = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Try registration and handle platform-specific errors
      UserCredential? credential;
      
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (platformError) {
        // Handle the platform-specific type casting error
        if (platformError.toString().contains('PigeonUserDetails')) {
          // Wait a moment and check if registration actually succeeded
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check if user was created despite the error
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.email == email) {
            if (kDebugMode) {
              print('Registration succeeded despite platform error');
            }
            
            // Show success and handle as if normal registration
            await _handleSuccessfulRegistration(currentUser);
            return;
          }
        }
        // Re-throw if it's not the known platform error
        throw platformError;
      }

      // Normal success path
      if (credential.user != null) {
        await _handleSuccessfulRegistration(credential.user!);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          switch (e.code) {
            case 'weak-password':
              error = 'The password provided is too weak.';
              break;
            case 'email-already-in-use':
              error = 'An account already exists with that email.';
              break;
            case 'invalid-email':
              error = 'Invalid email address.';
              break;
            default:
              error = e.message ?? 'Registration failed';
          }
        });
      }
    } catch (e) {
      // Handle any other errors
      if (kDebugMode) {
        print('Registration error: $e');
      }
      if (mounted) {
        setState(() => error = 'Registration failed. Please try again.');
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _handleSuccessfulRegistration(User user) async {
    try {
      // Only send email verification on mobile platforms
      if (!kIsWeb) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Email verification error: $e');
      }
      // Continue even if email verification fails
    }
    
    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kIsWeb 
            ? 'Registration successful!' 
            : 'Registration successful! Please check your email for verification.'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
      
      // Wait a bit then navigate back
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                enabled: !loading,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                  helperText: "At least 6 characters",
                ),
                enabled: !loading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
              ),
              const SizedBox(height: 24),
              
              if (error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Register",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
