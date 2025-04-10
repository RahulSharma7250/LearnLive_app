import 'package:flutter/material.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final bool isLoading;
  final Function(String email, String password, String? name, String? role) onSubmit;

  const AuthForm({
    Key? key,
    required this.isLogin,
    required this.isLoading,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _name = '';
  String _role = 'student';

  void _trySubmit() {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();
      widget.onSubmit(
        _email.trim(),
        _password.trim(),
        widget.isLogin ? null : _name.trim(),
        widget.isLogin ? null : _role,
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isDark ? Color(0xFF2A2E35) : Color(0xFFE5E7EB)), // Border/Line
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF60A5FA), width: 2), // Accent Color 1
      ),
      labelStyle: TextStyle(color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563)), // Text - Secondary
      hintStyle: TextStyle(color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563)), // Text - Secondary
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!widget.isLogin)
            TextFormField(
              key: const ValueKey('name'),
              decoration: _inputDecoration('Full Name', Icons.person),
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 3) {
                  return 'Please enter a valid name (at least 3 characters)';
                }
                return null;
              },
              onSaved: (value) {
                _name = value!;
              },
            ),
          if (!widget.isLogin) const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('email'),
            decoration: _inputDecoration('Email Address', Icons.email),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            onSaved: (value) {
              _email = value!;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('password'),
            decoration: _inputDecoration('Password', Icons.lock),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty || value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
            onSaved: (value) {
              _password = value!;
            },
          ),
          const SizedBox(height: 16),
          if (!widget.isLogin)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'I am a:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF60A5FA), // Accent Color 1
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Student'),
                        value: 'student',
                        groupValue: _role,
                        onChanged: (value) {
                          setState(() {
                            _role = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Teacher'),
                        value: 'teacher',
                        groupValue: _role,
                        onChanged: (value) {
                          setState(() {
                            _role = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _trySubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF60A5FA), // Accent Color 1
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.isLogin ? 'Login' : 'Sign Up',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
