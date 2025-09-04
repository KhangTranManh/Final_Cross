import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/course.dart';

class CourseRepository {
  static const String apiBase = 'http://10.0.2.2:5000';
  String? _token;

  CourseRepository({String? token}) : _token = token;

  void setToken(String token) {
    _token = token;
  }

  Future<List<Course>> getCourses() async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (_token != null) {
        headers['Authorization'] = 'Bearer $_token';
      }

      final response = await http.get(
        Uri.parse('$apiBase/courses'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Handle your backend response structure
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final coursesData = responseData['data'];
          if (coursesData is List) {
            return coursesData.map((courseJson) {
              // Each item might have nested structure like {id: "...", data: {...}}
              if (courseJson is Map<String, dynamic>) {
                // If the course data is nested under 'data' key
                if (courseJson.containsKey('data') && courseJson.containsKey('id')) {
                  final courseData = Map<String, dynamic>.from(courseJson['data']);
                  courseData['id'] = courseJson['id']; // Add ID to the data
                  return Course.fromJson(courseData);
                } else {
                  return Course.fromJson(Map<String, dynamic>.from(courseJson));
                }
              }
              return Course.fromJson({});
            }).toList();
          }
        }
        
        // Fallback: if response is directly a list
        if (responseData is List) {
          return responseData.map((courseJson) => Course.fromJson(Map<String, dynamic>.from(courseJson))).toList();
        }
        
        return [];
      } else {
        throw Exception('Failed to load courses: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching courses: $e');
      throw Exception('Error fetching courses: $e');
    }
  }

  Future<Course?> getCourseById(String id) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (_token != null) {
        headers['Authorization'] = 'Bearer $_token';
      }

      final response = await http.get(
        Uri.parse('$apiBase/courses/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          return Course.fromJson(Map<String, dynamic>.from(responseData['data']));
        }
        return Course.fromJson(Map<String, dynamic>.from(responseData));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load course: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching course: $e');
    }
  }
}
