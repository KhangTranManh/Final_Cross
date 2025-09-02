import 'package:flutter/material.dart';
import 'data/repositories/course_repository.dart';
import 'features/auth/routes.dart';
import 'features/course/routes.dart';

Route<dynamic> buildRoute(RouteSettings settings, CourseRepository repo) {
  // Try matching route from auth feature
  final authRoute = AuthRoutes.build(settings);
  if (authRoute != null) return authRoute;

  // Try matching route from course feature
  final courseRoute = CourseRoutes.build(settings, repo);
  if (courseRoute != null) return courseRoute;

  // Fallback: 404 route
  return MaterialPageRoute(
    builder: (_) => const Scaffold(
      body: Center(child: Text('404: Page Not Found')),
    ),
  );
}
