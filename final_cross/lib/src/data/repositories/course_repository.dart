import '../models/course.dart';

class CourseRepository {
  final List<Course> _seed;

  CourseRepository._(this._seed);

  factory CourseRepository.inMemory() => CourseRepository._([
        const Course(
          id: '1',
          title: 'Flutter Basics',
          description: 'Learn widgets, layouts, and navigation.',
          thumbnailUrl: 'https://picsum.photos/seed/flutter/200/200',
          lessonCount: 14,
        ),
        const Course(
          id: '2',
          title: 'Advanced Dart',
          description: 'Types, async, isolates, and more.',
          thumbnailUrl: 'https://picsum.photos/seed/dart/200/200',
          lessonCount: 10,
        ),
        const Course(
          id: '3',
          title: 'State Management',
          description: 'SetState, InheritedWidget, Provider intros.',
          thumbnailUrl: 'https://picsum.photos/seed/state/200/200',
          lessonCount: 12,
        ),
      ]);

  Future<List<Course>> getCourses() async {
    await Future.delayed(const Duration(milliseconds: 250)); // simulate network
    return _seed;
  }

  Future<Course> getCourseById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _seed.firstWhere((c) => c.id == id);
  }
}
