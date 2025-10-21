import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      if (kDebugMode) {
        return 'http://127.0.0.1:5001/elearning-5ac35/us-central1/api';
      } else {
        return 'https://us-central1-elearning-5ac35.cloudfunctions.net/api';
      }
    } else {
      if (kDebugMode) {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:5001/elearning-5ac35/us-central1/api';
        } else {
          return 'http://127.0.0.1:5001/elearning-5ac35/us-central1/api';
        }
      } else {
        return 'https://us-central1-elearning-5ac35.cloudfunctions.net/api';
      }
    }
  }
  
  // Course endpoints
  static String get coursesUrl => '$baseUrl/courses';
  static String courseByIdUrl(String id) => '$baseUrl/courses/$id';
  
  // Auth/Profile endpoints
  static String get profileUrl => '$baseUrl/auth/profile';
  static String get registerUrl => '$baseUrl/auth/register';
  
  // Enrollment endpoints
  static String get enrollmentsUrl => '$baseUrl/enrollments';
  static String get enrollUrl => '$baseUrl/enrollments/enroll';
  static String enrollmentCheckUrl(String courseId) => '$baseUrl/enrollments/check/$courseId';
  
  // Helper method to get headers with authentication
  static Map<String, String> getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
}