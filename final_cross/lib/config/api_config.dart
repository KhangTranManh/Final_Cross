import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // For web, use the Cloud Functions URL
      return 'https://us-central1-your-project-id.cloudfunctions.net/api';
    } else {
      // For mobile (development with emulator)
      if (kDebugMode) {
        return 'http://localhost:5001/your-project-id/us-central1/api'; // Local emulator
      } else {
        // Production mobile
        return 'https://us-central1-your-project-id.cloudfunctions.net/api';
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
  
  // Common headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
    // Headers with auth token
  static Map<String, String> authHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}