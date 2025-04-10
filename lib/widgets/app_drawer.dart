import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

const Color primaryPurple = Color(0xFF8852E5);

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isStudent = authProvider.isStudent;

    return Drawer(
      child: Column(
        children: [
          // Drawer header with user info
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'User'),
            accountEmail: Text(user?.email ?? 'user@example.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.name?.isNotEmpty ?? false)
                    ? user!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryPurple,
                ),
              ),
            ),
            decoration: const BoxDecoration(
              color: primaryPurple,
            ),
          ),

          // Dashboard
          _buildListTile(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed(
                isStudent ? '/student-dashboard' : '/teacher-dashboard',
              );
            },
          ),

          // Conditional student/teacher options
          if (isStudent)
            _buildListTile(
              icon: Icons.book,
              title: 'My Courses',
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigate to enrolled courses
              },
            )
          else
            _buildListTile(
              icon: Icons.add_box,
              title: 'Create Course',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/courses/create');
              },
            ),

          // Live Sessions
          _buildListTile(
            icon: Icons.video_call,
            title: 'Live Sessions',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/live_session_screen');
            },
          ),

          // Profile
          _buildListTile(
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Navigate to profile
            },
          ),

          const Divider(),

          // Settings
          _buildListTile(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Navigate to settings
            },
          ),

          // Help & Support
          _buildListTile(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Navigate to help & support
            },
          ),

          const Spacer(),

          const Divider(),

          // Logout
          _buildListTile(
            icon: Icons.exit_to_app,
            title: 'Logout',
            onTap: () async {
              await authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}
