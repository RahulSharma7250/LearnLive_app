import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

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
                Icon(Icons.school, size: 64, color: colorScheme.onPrimary),
                const SizedBox(height: 16),

                // App name
                Text(
                  'LearnLive',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Interactive Learning Platform',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 48),

                // Login form
                Card(
                  color:
                      theme.brightness == Brightness.dark
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
                          'Login',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                theme.brightness == Brightness.dark
                                    ? Color(0xFFE4E4E7)
                                    : Color(0xFF1F2937), // Text - Primary
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Auth form
                        AuthForm(
                          isLogin: true,
                          isLoading: authProvider.isLoading,
                          onSubmit: (email, password, _, role) async {
                            final success = await authProvider.login(
                              email,
                              password,
                            );
                            if (success) {
                              if (authProvider.isStudent) {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/student-dashboard');
                              } else {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/teacher-dashboard');
                              }
                            }
                          },
                        ),

                        if (authProvider.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              authProvider.error!,
                              style: TextStyle(
                                color:
                                    theme.brightness == Brightness.dark
                                        ? Color(0xFFEF4444)
                                        : Color(0xFFDC2626), // Error/Red
                                fontSize: 14,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Sign up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account?',
                              style: textTheme.bodyMedium?.copyWith(
                                color:
                                    theme.brightness == Brightness.dark
                                        ? Color(0xFF9CA3AF)
                                        : Color(0xFF4B5563), // Text - Secondary
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/signup');
                              },
                              child: Text(
                                'Sign Up',
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
