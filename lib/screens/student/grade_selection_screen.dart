import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class GradeSelectionScreen extends StatelessWidget {
  const GradeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3A8DFF), // Primary Gradient 1
              Color(0xFFA259FF), // Primary Gradient 2
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(context, isDark),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF161B22) : Color(0xFFF9FAFB), // Card Background
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Color(0xFF2A2E35) : Color(0xFFE5E7EB), // Border/Line
                        offset: const Offset(0, -2),
                        blurRadius: 12,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Choose Your Grade',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Color(0xFFE4E4E7) : Color(0xFF1F2937), // Text - Primary
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          padding: const EdgeInsets.only(bottom: 20),
                          children: [
                            _buildGradeCard(context, grade: '5', onTap: () => _selectGrade(context, '5', authProvider)),
                            _buildGradeCard(context, grade: '6', onTap: () => _selectGrade(context, '6', authProvider)),
                            _buildGradeCard(context, grade: '7', onTap: () => _selectGrade(context, '7', authProvider)),
                            _buildGradeCard(context, grade: '8', onTap: () => _selectGrade(context, '8', authProvider)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          authProvider.logout();
                          Navigator.of(context).pushReplacementNamed('/');
                        },
                        icon: const Icon(Icons.logout, color: Color(0xFFEF4444)), // Error/Red
                        label: const Text(
                          'Logout',
                          style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600), // Error/Red
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      children: [
        Icon(Icons.school, size: 64, color: Colors.white),
        const SizedBox(height: 12),
        const Text(
          'LearnLive',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Empowering Your Learning Journey',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeCard(
    BuildContext context, {
    required String grade,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [Color(0xFF161B22), Color(0xFF161B22)] // Card Background
                : [Color(0xFFF9FAFB), Color(0xFFF9FAFB)], // Card Background
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Color(0xFF2A2E35) : Color(0xFFE5E7EB), // Border/Line
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.15),
              ),
              child: Center(
                child: Text(
                  grade,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Grade $grade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Color(0xFFE4E4E7) : Color(0xFF1F2937), // Text - Primary
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to select',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563), // Text - Secondary
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectGrade(BuildContext context, String grade, AuthProvider authProvider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await authProvider.updateClassLevel(grade);
      if (context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed('/student-dashboard');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Color(0xFFEF4444), // Error/Red
          ),
        );
      }
    }
  }
}
