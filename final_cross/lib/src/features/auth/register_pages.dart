import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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

  Future<void> _register() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'Email and password are required');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    final baseUrl = dotenv.env['API_BASE'];
    final url = Uri.parse('$baseUrl/auth/register');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        String msg;
        try {
          final data = jsonDecode(res.body);
          msg = data['msg']?.toString() ?? res.body;
        } catch (_) {
          msg = res.body;
        }
        setState(() => error = '${res.statusCode} $msg');
      }
    } catch (e) {
      setState(() => error = 'Connection error: $e');
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
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    child: const Text("Register"),
                  ),
          ],
        ),
      ),
    );
  }
}
