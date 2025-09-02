import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'register_pages.dart';
import '../main_screen.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginPage({super.key, required this.onLoggedIn});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  bool showPassword = false;
  String? error;

  static const String apiBase = 'http://10.0.2.2:5000'; // or use dotenv for flexibility

  Future<void> _login() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });

    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    try {
      final res = await http.post(
        Uri.parse('$apiBase/auth/login'),
        headers: const {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = _safeJson(res.body);

      if (res.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('Login successful: ${data['token']}');
        }
        widget.onLoggedIn(); // tell the parent (MainScreen) we're logged in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        setState(() => error = data['msg']?.toString() ?? 'Login failed');
      }
    } catch (e) {
      setState(() => error = 'Connection error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Map<String, dynamic> _safeJson(String body) {
    try {
      final obj = jsonDecode(body);
      return obj is Map<String, dynamic> ? obj : {'raw': obj};
    } catch (_) {
      return {'msg': body};
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: !showPassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => showPassword = !showPassword),
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
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
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
