import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_sizes.dart';
import '../../data/repositories/course_repository.dart'; // Fixed import
import '../../routes.dart';
import '../../data/models/course.dart';
import 'course_detail_page.dart';

class CourseListPage extends StatelessWidget {
  final CourseRepository repo;
  const CourseListPage({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.courses)),
      body: FutureBuilder<List<Course>>(
        future: repo.getCourses(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final courses = snap.data ?? [];
          if (courses.isEmpty) {
            return const Center(child: Text('No courses yet'));
          }

          return ListView.separated(
            padding: pad16,
            itemCount: courses.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final c = courses[i];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(c.thumbnailUrl)),
                title: Text(c.title),
                subtitle: Text('${c.lessonCount} lessons'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.courseDetail,
                  arguments: CourseDetailArgs(course: c),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
