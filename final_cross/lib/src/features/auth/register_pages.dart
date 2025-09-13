import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // Use Firebase Auth instead of HTTP request
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Send email verification
        await credential.user!.sendEmailVerification();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please check your email for verification.'),
              duration: Duration(seconds: 3),
            ),
          );
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
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
    } catch (e) {
      setState(() => error = 'An unexpected error occurred: $e');
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                helperText: "At least 6 characters",
              ),
            ),
            const SizedBox(height: 24),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _register,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
