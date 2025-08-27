import 'package:flutter/material.dart';
import '../../data/models/course.dart';

class CourseDetailArgs {
  final Course course;
  CourseDetailArgs({required this.course});
}

class CourseDetailPage extends StatelessWidget {
  final Course course;
  const CourseDetailPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(course.thumbnailUrl),
            ),
            const SizedBox(height: 16),
            Text(course.description, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('${course.lessonCount} lessons',
                style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('Start Learning'),
            ),
          ],
        ),
      ),
    );
  }
}
