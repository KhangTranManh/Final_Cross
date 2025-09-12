import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserMenu extends StatelessWidget {
  final VoidCallback onLogout;
  
  const UserMenu({
    super.key,
    required this.onLogout,
  });

  Future<void> _logout(BuildContext context) async {
    // Clear stored token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    
    // Call logout callback
    onLogout();
    
    // Navigate to login
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/login', 
        (route) => false,
      );
    }
  }

  void _showProfile(BuildContext context) {
    // Navigate to profile page or show profile dialog
    Navigator.pushNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.settings,
        size: 28,
      ),
      offset: const Offset(0, 45),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            _showProfile(context);
            break;
          case 'logout':
            _logout(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}