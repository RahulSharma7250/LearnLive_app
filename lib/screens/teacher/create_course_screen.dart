import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({Key? key}) : super(key: key);

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedGrade = '5';

  final List<String> _grades = ['5', '6', '7', '8'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);

      final price = double.tryParse(_priceController.text) ?? 0.0;

      // Make sure we have the user data
      if (authProvider.user == null) {
        throw Exception('User data not available');
      }

      print('Creating course as teacher: ${authProvider.user!.id}, role: ${authProvider.user!.role}');

      final newCourse = Course(
        id: '', // Will be assigned by the backend
        title: _titleController.text,
        description: _descriptionController.text,
        grade: _selectedGrade,
        price: price,
        teacherId: authProvider.user!.id,
        teacherName: authProvider.user!.name,
      );

      final success = await courseProvider.createCourse(authProvider.token, newCourse);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course created successfully')),
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _error = courseProvider.error ?? 'Failed to create course';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Course'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFEF4444).withOpacity(0.2), // Error/Red
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFEF4444)), // Error/Red
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Color(0xFFEF4444)), // Error/Red
                  ),
                ),

              const Text(
                'Course Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF60A5FA), // Accent Color 1
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Course Title',
                  hintText: 'e.g., Mathematics for 6th Grade',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563)), // Text - Secondary
                  hintStyle: TextStyle(color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563)), // Text - Secondary
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a course title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Course Description',
                  hintText: 'Describe what students will learn in this course',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563)), // Text - Secondary
                  hintStyle: TextStyle(color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563)), // Text - Secondary
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a course description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Grade Level',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563)), // Text - Secondary
                ),
                value: _selectedGrade,
                items: _grades.map((grade) {
                  return DropdownMenuItem(
                    value: grade,
                    child: Text('Grade $grade'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGrade = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a grade level';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price (\$)',
                  hintText: '29.99',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563)), // Text - Secondary
                  hintStyle: TextStyle(color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563)), // Text - Secondary
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF60A5FA), // Accent Color 1
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Course'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
