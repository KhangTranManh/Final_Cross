import 'package:flutter/material.dart';
import 'course_list_page.dart';
import 'course_detail_page.dart';
import '../../data/repositories/course_repository.dart';

class CourseRoutes {
  static const courses = '/courses';
  static const courseDetail = '/courses/detail';

  static Route<dynamic>? build(RouteSettings settings, CourseRepository repo) {
    switch (settings.name) {
      case courses:
        return MaterialPageRoute(
          builder: (_) => CourseListPage(repo: repo),
        );

      case courseDetail:
        final args = settings.arguments;
        if (args is CourseDetailArgs) {
          return MaterialPageRoute(
            builder: (_) => CourseDetailPage(course: args.course),
          );
        } else {
          return _errorRoute('Missing course detail data');
        }
    }

    return null;
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text(message)),
      ),
    );
  }
}
