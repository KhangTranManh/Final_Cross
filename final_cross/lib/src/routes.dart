import 'package:flutter/material.dart';
import 'data/repositories/course_repository.dart';
import 'features/auth/login_pages.dart';
import 'features/course/course_list_page.dart';
import 'features/course/course_detail_page.dart';

class AppRoutes {
  static const login = '/login';
  static const courses = '/courses';
  static const courseDetail = '/courses/detail';
}

Route<dynamic> buildRoute(RouteSettings settings, CourseRepository repo) {
  switch (settings.name) {
    case AppRoutes.login:
      return MaterialPageRoute(builder: (context) => LoginPage(onLoggedIn: () {
        Navigator.pushReplacementNamed(context, AppRoutes.courses);
      }));

    case AppRoutes.courses:
      return MaterialPageRoute(builder: (_) => CourseListPage(repo: repo));

    case AppRoutes.courseDetail:
      final args = settings.arguments as CourseDetailArgs;
      return MaterialPageRoute(
        builder: (_) => CourseDetailPage(course: args.course),
      );

    default:
      return MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('404'))),
      );
  }
}
