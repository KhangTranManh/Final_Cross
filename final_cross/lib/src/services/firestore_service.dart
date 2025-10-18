import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/course.dart';
import '../../../config/api_config.dart';

class FirestoreService {
  // Simulate real-time updates by polling the API
  static Stream<List<Course>> getCoursesStream({
    String? category,
    String? difficulty,
    String? searchQuery,
  }) {
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => _fetchCoursesFromAPI(category, difficulty, searchQuery));
  }

  static Stream<Course?> getCourseStream(String courseId) {
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => _fetchCourseById(courseId));
  }

  static Stream<List<Course>> getUserEnrolledCoursesStream(String userId) {
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => _fetchUserEnrollments(userId));
  }

  // Helper methods to fetch from your existing API
  static Future<List<Course>> _fetchCoursesFromAPI(
    String? category,
    String? difficulty,
    String? searchQuery,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      String? token;
      if (user != null) {
        token = await user.getIdToken(false);
      }

      final url = ApiConfig.coursesUrl;
      final headers = ApiConfig.getHeaders(token: token);

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData is Map<String, dynamic> && 
            responseData.containsKey('success') && 
            responseData['success'] == true) {
          final coursesData = responseData['data'];
          
          if (coursesData is List) {
            List<Course> courses = coursesData.map((courseJson) {
              if (courseJson is Map<String, dynamic>) {
                return Course.fromJson(Map<String, dynamic>.from(courseJson));
              }
              return Course.fromJson({});
            }).toList();
            
            // Apply filters locally
            if (category != null && category.isNotEmpty) {
              courses = courses.where((course) => course.category == category).toList();
            }
            
            if (difficulty != null && difficulty.isNotEmpty) {
              courses = courses.where((course) => course.difficulty.toLowerCase() == difficulty.toLowerCase()).toList();
            }
            
            if (searchQuery != null && searchQuery.isNotEmpty) {
              courses = courses.where((course) {
                return course.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                       course.instructor.toLowerCase().contains(searchQuery.toLowerCase());
              }).toList();
            }
            
            return courses;
          }
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  static Future<Course?> _fetchCourseById(String courseId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      String? token;
      if (user != null) {
        token = await user.getIdToken(false);
      }

      final url = ApiConfig.courseByIdUrl(courseId);
      final headers = ApiConfig.getHeaders(token: token);

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          return Course.fromJson(Map<String, dynamic>.from(responseData['data']));
        }
        return Course.fromJson(Map<String, dynamic>.from(responseData));
      }
      
      return null;
    } catch (e) {
      print('Error fetching course: $e');
      return null;
    }
  }

  static Future<List<Course>> _fetchUserEnrollments(String userId) async {
    // This would need to be implemented in your API
    // For now, return empty list
    return [];
  }
}
