class Course {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final int lessonCount;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.lessonCount,
  });
}
