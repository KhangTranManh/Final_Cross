import 'package:flutter/material.dart';
import 'login_pages.dart';

class AuthRoutes {
  static const login = '/login';

  static Route<dynamic>? build(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (context) => LoginPage(
            onLoggedIn: () {
              Navigator.pushReplacementNamed(context, '/courses'); // Changed from '/course-list'
            },
          ),
        );
    }
    return null;
  }
}