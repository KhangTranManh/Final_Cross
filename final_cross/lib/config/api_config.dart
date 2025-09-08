import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000'; // Web
    } else {
      return 'http://10.0.2.2:5000'; // Android emulator
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
  
  static Map<String, String> headersWithAuth(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}