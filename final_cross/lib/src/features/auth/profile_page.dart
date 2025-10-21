import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'No user logged in';
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get Firebase ID token
      final idToken = await user!.getIdToken();
      
      print('=== PROFILE DEBUG ===');
      print('Profile URL: ${ApiConfig.profileUrl}');
      print('Has token: ${idToken != null}');
      
      // Make API call to get profile
      final response = await http.get(
        Uri.parse(ApiConfig.profileUrl),
        headers: ApiConfig.getHeaders(token: idToken),
      ).timeout(const Duration(seconds: 10));

      print('Profile response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Profile loaded successfully');
        setState(() {
          userData = data['user'];
          isLoading = false;
        });
      } else {
        print('❌ Failed to load profile: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> updates) async {
    if (user == null) return;

    try {
      final idToken = await user!.getIdToken();
      
      final response = await http.put(
        Uri.parse(ApiConfig.profileUrl),
        headers: ApiConfig.getHeaders(token: idToken),
        body: json.encode(updates),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Reload profile data
        await _loadUserProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
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
            Text('Loading profile...'),
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
              onPressed: _loadUserProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (userData == null) {
      return const Center(child: Text('No profile data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundImage: userData!['profile_picture_url'] != null
                  ? NetworkImage(userData!['profile_picture_url'])
                  : null,
              child: userData!['profile_picture_url'] == null
                  ? Text(
                      userData!['display_name']?.isNotEmpty == true
                          ? userData!['display_name'][0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Profile Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileField('Name', userData!['display_name'] ?? 'Not set'),
                    _buildProfileField('Email', userData!['email'] ?? ''),
                    _buildProfileField('Phone', userData!['phone'] ?? 'Not set'),
                    _buildProfileField('Bio', userData!['bio'] ?? 'Not set'),
                    _buildProfileField('Role', userData!['role'] ?? 'Student'),
                    _buildProfileField('Enrollments', userData!['enrollment_count']?.toString() ?? '0'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Edit Profile Button
            ElevatedButton(
              onPressed: () => _showEditDialog(),
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: userData!['display_name'] ?? '');
    final phoneController = TextEditingController(text: userData!['phone'] ?? '');
    final bioController = TextEditingController(text: userData!['bio'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updates = {
                'display_name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
                'bio': bioController.text.trim(),
              };
              Navigator.pop(context);
              _updateProfile(updates);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}