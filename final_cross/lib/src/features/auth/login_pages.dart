import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  // For Android emulator use 10.0.2.2, for iOS simulator 127.0.0.1,
  // for real device use your PC LAN IP (e.g., http://192.168.1.100:5000)
  static const String apiBase = 'http://10.0.2.2:5000';

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

      if (res.statusCode == 200) {
        // try parse token
        final data = _safeJson(res.body);
        if (kDebugMode) {
          debugPrint('Login OK: ${data['token']}');
        }
        widget.onLoggedIn();
      } else {
        final data = _safeJson(res.body);
        setState(() => error = data['msg']?.toString() ?? 'Login failed (${res.statusCode})');
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
      return (obj is Map<String, dynamic>) ? obj : <String, dynamic>{'raw': obj};
    } catch (_) {
      return {'msg': body}; // backend might have sent plain text
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
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
          ],
        ),
      ),
    );
  }
}
