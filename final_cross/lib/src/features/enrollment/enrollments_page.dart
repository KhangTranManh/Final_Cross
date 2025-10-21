import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';

class EnrollmentsPage extends StatefulWidget {
  const EnrollmentsPage({super.key});

  @override
  State<EnrollmentsPage> createState() => _EnrollmentsPageState();
}

class _EnrollmentsPageState extends State<EnrollmentsPage> {
  List<Map<String, dynamic>> enrollments = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Please log in to view enrollments';
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final idToken = await user.getIdToken();
      
      print('=== ENROLLMENTS DEBUG ===');
      print('Enrollments URL: ${ApiConfig.enrollmentsUrl}');
      
      final response = await http.get(
        Uri.parse(ApiConfig.enrollmentsUrl),
        headers: ApiConfig.getHeaders(token: idToken),
      ).timeout(const Duration(seconds: 10));

      print('Enrollments response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Enrollments loaded: ${data['count'] ?? 0}');
        setState(() {
          enrollments = List<Map<String, dynamic>>.from(data['enrollments'] ?? []);
          isLoading = false;
        });
      } else {
        print('❌ Failed to load enrollments: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load enrollments: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Enrollments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnrollments,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading enrollments...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEnrollments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (enrollments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Enrollments Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Start exploring courses to enroll!'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEnrollments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: enrollments.length,
        itemBuilder: (context, index) {
          final enrollment = enrollments[index];
          final course = enrollment['course'];
          final progress = enrollment['progress'] ?? {};
          
          return _buildEnrollmentCard(enrollment, course, progress);
        },
      ),
    );
  }

  Widget _buildEnrollmentCard(Map<String, dynamic> enrollment, Map<String, dynamic>? course, Map<String, dynamic> progress) {
    if (course == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.error),
          title: Text('Course information unavailable'),
        ),
      );
    }

    final completionPercentage = progress['completion_percentage']?.toDouble() ?? 0.0;
    final status = enrollment['status'] ?? 'active';
    final enrolledDate = enrollment['enrolled_at'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    course['title'] ?? 'Unknown Course',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Instructor
            if (course['instructor']?.isNotEmpty == true)
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    course['instructor'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            
            const SizedBox(height: 12),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progress'),
                    Text('${completionPercentage.toInt()}%'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: completionPercentage / 100,
                  backgroundColor: Colors.grey.shade300,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Learning Stats
            Row(
              children: [
                if (progress['completed_lessons']?.isNotEmpty == true) ...[
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('${progress['completed_lessons'].length} lessons completed'),
                  const SizedBox(width: 16),
                ],
                if (progress['total_time_spent'] != null) ...[
                  const Icon(Icons.access_time, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('${progress['total_time_spent']} min'),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to course content
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening ${course['title']}...'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    child: Text(status == 'completed' ? 'Review' : 'Continue'),
                  ),
                ),
                if (status == 'completed') ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _showReviewDialog(enrollment),
                    child: const Text('Review'),
                  ),
                ],
              ],
            ),
            
            // Enrollment Date
            if (enrolledDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Enrolled: ${DateTime.parse(enrolledDate).toLocal().toString().split(' ')[0]}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'Completed';
        break;
      case 'dropped':
        color = Colors.red;
        text = 'Dropped';
        break;
      default:
        color = Colors.blue;
        text = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> enrollment) {
    final course = enrollment['course'];
    final existingRating = enrollment['rating'];
    final existingReview = enrollment['review'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review ${course['title']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (existingRating != null) ...[
              Text('Your Rating: ${existingRating}/5 stars'),
              if (existingReview?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('Your Review: $existingReview'),
              ],
            ] else ...[
              const Text('Add your rating and review for this course'),
              // TODO: Add rating and review input widgets
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (existingRating == null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement review submission
              },
              child: const Text('Submit Review'),
            ),
        ],
      ),
    );
  }
}