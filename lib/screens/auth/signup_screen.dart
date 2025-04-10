import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_form.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo
                Icon(
                  Icons.school,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),

                // App name
                Text(
                  'LearnLive',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? Color(0xFFE4E4E7)
                        : Color(0xFF1F2937), // Text - Primary
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Interactive Learning Platform',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.brightness == Brightness.dark
                        ? Color(0xFF9CA3AF)
                        : Color(0xFF4B5563), // Text - Secondary
                  ),
                ),
                const SizedBox(height: 48),

                // Signup form
                Card(
                  color: theme.brightness == Brightness.dark
                      ? Color(0xFF161B22)
                      : Color(0xFFF9FAFB), // Card Background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.brightness == Brightness.dark
                                ? Color(0xFFE4E4E7)
                                : Color(0xFF1F2937), // Text - Primary
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Auth form
                        AuthForm(
                          isLogin: false,
                          isLoading: authProvider.isLoading,
                          onSubmit: (email, password, name, role) async {
                            final success = await authProvider.signup(name!, email, password, role!);
                            if (success) {
                              // Navigate to login screen
                              Navigator.of(context).pushReplacementNamed('/login');

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Account created successfully. Please login.'),
                                  backgroundColor: Color(0xFF10B981), // Success/Green
                                ),
                              );
                            }
                          },
                        ),

                        if (authProvider.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              authProvider.error!,
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Color(0xFFEF4444)
                                    : Color(0xFFDC2626), // Error/Red
                                fontSize: 14,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Color(0xFF9CA3AF)
                                    : Color(0xFF4B5563), // Text - Secondary
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: Color(0xFF60A5FA), // Accent Color 1
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
