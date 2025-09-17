import 'package:flutter/material.dart';
import '../../data/models/course.dart';
import '../../data/repositories/course_repository.dart';

class CourseDetailPage extends StatefulWidget {
  final Course course;
  const CourseDetailPage({super.key, required this.course});
  
  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final CourseRepository _repository = CourseRepository();
  Future<Course?>? _courseDetailFuture;
  
  @override
  void initState() {
    super.initState();
    // Fetch detailed course data including lessons array
    _courseDetailFuture = _repository.getCourseById(widget.course.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<Course?>(
        future: _courseDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading course details...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading course details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _courseDetailFuture = _repository.getCourseById(widget.course.id);
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final course = snapshot.data ?? widget.course;
          return _buildCourseDetail(course);
        },
      ),
    );
  }

  Widget _buildCourseDetail(Course course) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header
          _buildCourseHeader(course),
          const SizedBox(height: 24),
          
          // Course Info Cards
          _buildCourseInfo(course),
          const SizedBox(height: 24),
          
          // Description
          if (course.description.isNotEmpty) ...[
            _buildSectionTitle('Description'),
            const SizedBox(height: 8),
            Text(
              course.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
          ],
          
          // Lessons (if available)
          if (course.lessons.isNotEmpty) ...[
            _buildSectionTitle('Lessons'),
            const SizedBox(height: 8),
            _buildLessonsList(course.lessons),
            const SizedBox(height: 24),
          ],
          
          // Enroll Button
          _buildEnrollButton(course),
        ],
      ),
    );
  }

  Widget _buildCourseHeader(Course course) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (course.instructor.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Instructor: ${course.instructor}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (course.rating > 0) ...[
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('${course.rating.toStringAsFixed(1)}'),
                  const SizedBox(width: 16),
                ],
                if (course.studentsCount > 0) ...[
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 4),
                  Text('${course.studentsCount} students'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfo(Course course) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'Duration',
            course.duration > 0 ? '${course.duration} min' : 'Not specified',
            Icons.access_time,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            'Difficulty',
            course.difficulty.isNotEmpty ? course.difficulty : 'Not specified',
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            'Price',
            course.price > 0 ? '\$${course.price.toStringAsFixed(2)}' : 'Free',
            Icons.attach_money,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLessonsList(List<dynamic> lessons) {
    return Card(
      child: Column(
        children: lessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          final lessonTitle = lesson is Map ? lesson['title'] ?? 'Lesson ${index + 1}' : 'Lesson ${index + 1}';
          final lessonDuration = lesson is Map ? lesson['duration'] ?? 0 : 0;
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text('${index + 1}'),
            ),
            title: Text(lessonTitle),
            trailing: lessonDuration > 0 
                ? Text('${lessonDuration} min')
                : null,
            onTap: () {
              // TODO: Navigate to lesson detail or video player
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Selected: $lessonTitle')),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnrollButton(Course course) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement enrollment logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Enrolled in ${course.title}!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        child: Text(
          course.price > 0 ? 'Enroll - \$${course.price.toStringAsFixed(2)}' : 'Enroll for Free',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}