import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class StudentAuthScreen extends StatefulWidget {
  const StudentAuthScreen({Key? key}) : super(key: key);

  @override
  State<StudentAuthScreen> createState() => _StudentAuthScreenState();
}

class _StudentAuthScreenState extends State<StudentAuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success;

      if (_isLogin) {
        success = await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        success = await authProvider.signup(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
          'student',
        );
      }

      if (success) {
        if (_isLogin) {
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushReplacementNamed('/student/grade-selection');
        } else {
          if (!mounted) return;
          setState(() {
            _isLogin = true;
            _nameController.clear();
            _emailController.clear();
            _passwordController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please login.'),
              backgroundColor: Color(0xFF10B981), // Success/Green
            ),
          );
        }
      } else {
        setState(() {
          _error = authProvider.error ?? 'Authentication failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: theme.brightness == Brightness.dark
              ? Color(0xFF2A2E35)
              : Color(0xFFE5E7EB), // Border/Line
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Color(0xFF60A5FA), // Accent Color 1
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.school, size: 64, color: Colors.white),
                const SizedBox(height: 16),
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
                Text(
                  'Student Portal',
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.brightness == Brightness.dark
                        ? Color(0xFF9CA3AF)
                        : Color(0xFF4B5563), // Text - Secondary
                  ),
                ),
                const SizedBox(height: 48),
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
                          _isLogin ? 'Student Login' : 'Student Sign Up',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.brightness == Brightness.dark
                                ? Color(0xFFE4E4E7)
                                : Color(0xFF1F2937), // Text - Primary
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? Color(0xFFEF4444).withOpacity(0.2)
                                  : Color(0xFFDC2626).withOpacity(0.2), // Error/Red
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.brightness == Brightness.dark
                                    ? Color(0xFFEF4444)
                                    : Color(0xFFDC2626), // Error/Red
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Color(0xFFEF4444)
                                    : Color(0xFFDC2626), // Error/Red
                              ),
                            ),
                          ),
                        if (_error != null) const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!_isLogin)
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _buildInputDecoration(
                                    'Full Name',
                                    Icons.person,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty ||
                                        value.length < 3) {
                                      return 'Please enter a valid name (at least 3 characters)';
                                    }
                                    return null;
                                  },
                                ),
                              if (!_isLogin) const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: _buildInputDecoration(
                                  'Email Address',
                                  Icons.email,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      !value.contains('@')) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: _buildInputDecoration(
                                  'Password',
                                  Icons.lock,
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value.length < 6) {
                                    return 'Password must be at least 6 characters long';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF60A5FA), // Accent Color 1
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _isLogin ? 'Login' : 'Sign Up',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? 'Don\'t have an account?'
                                  : 'Already have an account?',
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Color(0xFF9CA3AF)
                                    : Color(0xFF4B5563), // Text - Secondary
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _error = null;
                                });
                              },
                              child: Text(
                                _isLogin ? 'Sign Up' : 'Login',
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
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: Text(
                    'Back to Role Selection',
                    style: TextStyle(
                      color: theme.brightness == Brightness.dark
                          ? Color(0xFFE4E4E7)
                          : Color(0xFF1F2937), // Text - Primary
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
