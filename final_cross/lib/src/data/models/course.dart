class Course {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final int duration;
  final String difficulty;
  final String thumbnailUrl;
  final double price;
  final double rating;
  final int studentsCount;
  final String category;
  final List<dynamic> lessons;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.duration,
    required this.difficulty,
    required this.thumbnailUrl,
    required this.price,
    required this.rating,
    required this.studentsCount,
    required this.category,
    required this.lessons,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    // Handle the nested data structure from your backend
    final data = json['data'] ?? json; // Handle both direct and nested formats
    
    return Course(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      instructor: data['instructor']?.toString() ?? '',
      duration: _parseToInt(data['duration']),
      difficulty: data['difficulty']?.toString() ?? 'Beginner',
      thumbnailUrl: data['thumbnail']?.toString() ?? 'https://via.placeholder.com/150',
      price: _parseToDouble(data['price']),
      rating: _parseToDouble(data['rating']),
      studentsCount: _parseToInt(data['studentsCount']),
      category: data['category']?.toString() ?? '',
      lessons: data['lessons'] is List ? data['lessons'] : [],
      isPublished: data['isPublished'] == true,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  // Helper methods to safely parse different data types
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    // Handle Firestore Timestamp format
    if (value is Map<String, dynamic> && value.containsKey('_seconds')) {
      final seconds = _parseToInt(value['_seconds']);
      final nanoseconds = _parseToInt(value['_nanoseconds']);
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + nanoseconds ~/ 1000000);
    }
    
    // Handle ISO string format
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  int get lessonCount => lessons.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructor': instructor,
      'duration': duration,
      'difficulty': difficulty,
      'thumbnail': thumbnailUrl,
      'price': price,
      'rating': rating,
      'studentsCount': studentsCount,
      'category': category,
      'lessons': lessons,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
