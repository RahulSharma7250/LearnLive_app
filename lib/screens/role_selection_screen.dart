import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3A8DFF), // Primary Gradient 1
              Color(0xFFA259FF), // Primary Gradient 2
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo and App Name
              Icon(Icons.school, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'LearnLive',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Color(0xFFE4E4E7) : Color(0xFF1F2937), // Text - Primary
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Interactive Learning Platform',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563), // Text - Secondary
                ),
              ),

              const SizedBox(height: 60),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'I am a...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Color(0xFFE4E4E7) : Color(0xFF1F2937), // Text - Primary
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Student Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildRoleCard(
                  context,
                  title: 'Student',
                  description: 'Access interactive courses and live sessions',
                  icon: Icons.person_outline,
                  onTap: () {
                    Navigator.of(context).pushNamed('/student/auth');
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Teacher Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildRoleCard(
                  context,
                  title: 'Teacher',
                  description: 'Create courses and conduct live sessions',
                  icon: Icons.school_outlined,
                  onTap: () {
                    Navigator.of(context).pushNamed('/teacher/auth');
                  },
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  '© 2025 LearnLive. All rights reserved.',
                  style: TextStyle(
                    color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563), // Text - Secondary
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 6,
      color: isDark ? Color(0xFF161B22) : Color(0xFFF9FAFB), // Card Background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(0xFF60A5FA).withOpacity(0.1), // Accent Color 1
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: Color(0xFF60A5FA), // Accent Color 1
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Color(0xFFE4E4E7) : Color(0xFF1F2937), // Text - Primary
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563), // Text - Secondary
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563), // Text - Secondary
              ),
            ],
          ),
        ),
      ),
    );
  }
}
