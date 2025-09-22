import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_pages.dart';

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
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Remove automatic auth check to avoid conflicts
    // Let the AuthWrapper in main.dart handle this
  }

  void _navigateToCourses() {
    if (mounted && !_isNavigating) {
      _isNavigating = true;
      Navigator.pushReplacementNamed(context, '/courses').then((_) {
        if (mounted) {
          _isNavigating = false;
        }
      }).catchError((error) {
        if (mounted) {
          _isNavigating = false;
        }
      });
    }
  }

  Future<void> _login() async {
    if (loading || _isNavigating) return;
    
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        setState(() => error = 'Email and password are required');
      }
      return;
    }

    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      // Platform-specific approach to avoid type casting issues
      UserCredential? credential;
      
      // Try the login and handle the specific platform error
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (platformError) {
        // If we get the platform-specific error, try alternative approach
        if (platformError.toString().contains('PigeonUserDetails')) {
          // Wait a moment and check if auth actually succeeded
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check if user is now authenticated despite the error
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            if (kDebugMode) {
              print('Login succeeded despite platform error');
            }
            
            if (mounted && !_isNavigating) {
              // Navigate to courses
              _navigateToCourses();
              widget.onLoggedIn?.call();
            }
            return;
          }
        }
        // Re-throw if it's not the known platform error
        throw platformError;
      }

      // Normal success path
      if (credential.user != null && mounted) {
        if (mounted) {
          setState(() => error = null);
        }
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (mounted && !_isNavigating) {
          _navigateToCourses();
          widget.onLoggedIn?.call();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuth error: ${e.code} - ${e.message}');
      }
      
      if (mounted) {
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
            case 'invalid-credential':
              error = 'Invalid email or password.';
              break;
            case 'network-request-failed':
              error = 'Network error. Please check your connection.';
              break;
            case 'too-many-requests':
              error = 'Too many failed attempts. Please try again later.';
              break;
            default:
              error = 'Login failed. Please try again.';
          }
        });
      }
    } catch (e) {
      // Handle any other errors (including platform-specific type casting)
      if (kDebugMode) {
        print('General login error: $e');
      }
      
      if (mounted) {
        setState(() {
          error = 'Login failed. Please check your connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _navigateToRegister() {
    if (mounted && !loading && !_isNavigating) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RegisterPage(),
        ),
      );
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
      appBar: AppBar(
        title: const Text('Login'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              
              // App Logo or Title
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 50),
              
              // Error display
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
              
              // Email field
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !loading,
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // Password field
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: loading ? null : () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
                obscureText: !showPassword,
                enabled: !loading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),
              
              // Login button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading || _isNavigating ? null : _login,
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
                          'Login',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Register button
              TextButton(
                onPressed: loading || _isNavigating ? null : _navigateToRegister,
                child: const Text('Don\'t have an account? Register'),
              ),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
