import 'package:flutter/material.dart';
import 'package:final_cross/src/features/course/routes.dart'; // ✅ For route constants
import '../../constants/app_strings.dart';
import '../../constants/app_sizes.dart';
import '../../data/repositories/course_repository.dart';
import '../../data/models/course.dart';
import 'course_detail_page.dart'; // You can keep this for CourseDetailArgs
import '../auth/user_menu.dart';

class CourseListPage extends StatefulWidget {
  const CourseListPage({super.key});

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  final CourseRepository repo = CourseRepository(); // Initialize your repository here

  void _handleLogout() {
    // Clear any local state if needed
    setState(() {
      // Reset any user-specific data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          UserMenu(
            onLogout: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                  CourseRoutes.courseDetail,
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
