import 'package:flutter/material.dart';
import 'course_list_page.dart';
import 'course_detail_page.dart';
import '../../data/models/course.dart';

class CourseDetailArgs {
  final Course course;
  CourseDetailArgs({required this.course});
}

class CourseRoutes {
  static const courses = '/courses';
  static const courseList = '/course-list'; // Add this
  static const courseDetail = '/courses/detail';

  static Route<dynamic>? build(RouteSettings settings) {
    switch (settings.name) {
      case courses:
      case courseList: // Handle both routes
        return MaterialPageRoute(
          builder: (_) => const CourseListPage(),
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
        
      default:
        return null;
    }
  }
  
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
