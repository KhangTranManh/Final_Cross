import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course.dart';
import '../../../config/api_config.dart';

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
      final token = await _getFirebaseToken();
      
      // Debug: Print all URL components
      print('=== URL DEBUG ===');
      print('ApiConfig.baseUrl: ${ApiConfig.baseUrl}');
      print('ApiConfig.coursesUrl: ${ApiConfig.coursesUrl}');
      print('Platform: ${kIsWeb ? "Web" : (Platform.isAndroid ? "Android" : "iOS/Other")}');
      print('Debug mode: $kDebugMode');
      print('================');
      
      final url = ApiConfig.coursesUrl;
      final headers = ApiConfig.getHeaders(token: token);

      print('Making request to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Handle the response structure from your Python function
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('success') && responseData['success'] == true) {
            // Response format: {"success": true, "data": [...], "count": 3}
            final coursesData = responseData['data'];
            if (coursesData is List) {
              return coursesData.map((courseJson) {
                if (courseJson is Map<String, dynamic>) {
                  return Course.fromJson(Map<String, dynamic>.from(courseJson));
                }
                return Course.fromJson({});
              }).toList();
            }
          }
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
      final token = await _getFirebaseToken();
      final url = ApiConfig.courseByIdUrl(id); // Use the config
      
      final headers = ApiConfig.getHeaders(token: token); // Use the config

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
}