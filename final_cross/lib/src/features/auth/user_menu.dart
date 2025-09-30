import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';

class UserMenu extends StatelessWidget {
  final VoidCallback? onLogout;

  const UserMenu({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        child: Text(
          user?.displayName?.isNotEmpty == true
              ? user!.displayName![0].toUpperCase()
              : user?.email?.isNotEmpty == true
                  ? user!.email![0].toUpperCase()
                  : 'U',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            // Use MaterialPageRoute instead of named route
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilePage(),
              ),
            );
            break;
          case 'logout':
            await FirebaseAuth.instance.signOut();
            if (onLogout != null) onLogout!();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person),
              const SizedBox(width: 8),
              Text(user?.displayName ?? user?.email ?? 'User'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
        ),
      ],
    );
  }
}