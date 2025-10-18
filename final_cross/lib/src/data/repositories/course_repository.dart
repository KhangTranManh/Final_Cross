import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course.dart';
import '../../../config/api_config.dart';
import '../../services/firestore_service.dart';

class CourseRepository {
  String? _token;

  CourseRepository({String? token}) : _token = token;

  void setToken(String token) {
    _token = token;
  }

  // Get Firebase ID token for authentication
  Future<String?> _getFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken(false);
      }
      
      // Fallback to stored token
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting Firebase token: $e');
      return null;
    }
  }

  Future<List<Course>> getCourses() async {
    try {
      print('=== COURSE REPOSITORY DEBUG ===');
      
      final token = await _getFirebaseToken();
      final url = ApiConfig.coursesUrl;
      
      print('Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}');
      print('Base URL: ${ApiConfig.baseUrl}');
      print('Full URL: $url');
      print('Has token: ${token != null}');
      print('================================');
      
      final headers = ApiConfig.getHeaders(token: token);

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        // Check if response is HTML instead of JSON
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          throw Exception('API returned HTML instead of JSON. Check Firebase emulators are running.');
        }
        
        final responseData = jsonDecode(response.body);
        print('✅ JSON parsed successfully');
        
        // Handle the response structure from your Python function
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('success') && responseData['success'] == true) {
            final coursesData = responseData['data'];
            
            if (coursesData is List) {
              final courses = coursesData.map((courseJson) {
                if (courseJson is Map<String, dynamic>) {
                  return Course.fromJson(Map<String, dynamic>.from(courseJson));
                }
                return Course.fromJson({});
              }).toList();
              
              print('✅ Successfully parsed ${courses.length} courses');
              return courses;
            }
          }
        }
        
        throw Exception('Invalid response format from API');
      } else {
        throw Exception('Failed to load courses: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching courses: $e');
      throw Exception('Error fetching courses: $e');
    }
  }

  Future<Course?> getCourseById(String id) async {
    try {
      final token = await _getFirebaseToken();
      final url = ApiConfig.courseByIdUrl(id);
      
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
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load course: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching course: $e');
    }
  }

  // Real-time stream methods using Firestore
  Stream<List<Course>> getCoursesStream({
    String? category,
    String? difficulty,
    String? searchQuery,
  }) {
    return FirestoreService.getCoursesStream(
      category: category,
      difficulty: difficulty,
      searchQuery: searchQuery,
    );
  }

  Stream<Course?> getCourseStream(String courseId) {
    return FirestoreService.getCourseStream(courseId);
  }

  Stream<List<Course>> getUserEnrolledCoursesStream(String userId) {
    return FirestoreService.getUserEnrolledCoursesStream(userId);
  }
}