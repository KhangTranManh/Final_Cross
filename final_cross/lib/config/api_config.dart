import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      if (kDebugMode) {
        // CORRECT URL for web development with emulator
        return 'http://127.0.0.1:5001/elearning-5ac35/us-central1/api';
      } else {
        return 'https://us-central1-elearning-5ac35.cloudfunctions.net/api';
      }
    } else {
      if (kDebugMode) {
        if (Platform.isAndroid) {
          // CORRECT URL for Android emulator
          return 'http://10.0.2.2:5001/elearning-5ac35/us-central1/api';
        } else {
          // CORRECT URL for iOS simulator
          return 'http://127.0.0.1:5001/elearning-5ac35/us-central1/api';
        }
      } else {
        return 'https://us-central1-elearning-5ac35.cloudfunctions.net/api';
      }
    }
  }
  
  // Auth endpoints
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get logoutUrl => '$baseUrl/auth/logout';
  
  // Course endpoints
  static String get coursesUrl => '$baseUrl/courses';
  static String courseByIdUrl(String id) => '$baseUrl/courses/$id';
  
  // Category endpoints
  static String get categoriesUrl => '$baseUrl/categories';
  static String categoryByIdUrl(String id) => '$baseUrl/categories/$id';
  
  // Enrollment endpoints
  static String get enrollmentsUrl => '$baseUrl/enrollments';
  static String enrollmentByIdUrl(String id) => '$baseUrl/enrollments/$id';
  
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