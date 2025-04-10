import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/course.dart';
import '../../models/course_material.dart';

class CourseExploreScreen extends StatefulWidget {
  const CourseExploreScreen({Key? key}) : super(key: key);

  @override
  State<CourseExploreScreen> createState() => _CourseExploreScreenState();
}

class _CourseExploreScreenState extends State<CourseExploreScreen> {
  bool _isLoading = true;
  bool _isEnrolled = false;
  String? _error;
  Course? _course;
  List<CourseMaterial> _materials = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseDetails();
    });
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final courseId = args['courseId'] as String;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);

      // First check if we're enrolled using the efficient method
      final isEnrolled = courseProvider.isEnrolledInCourse(courseId);

      final course = await courseProvider.fetchCourseDetails(authProvider.token, courseId);
      if (course == null) {
        setState(() {
          _error = courseProvider.error ?? 'Failed to load course details';
          _isLoading = false;
        });
        return;
      }

      final materials = await courseProvider.fetchCourseMaterials(authProvider.token, courseId);

      setState(() {
        _course = course;
        _isEnrolled = isEnrolled;
        _materials = materials;
        _isLoading = false;
      });

      // Log enrollment status for debugging
      print('Course ${course.title} (ID: ${course.id}) - Enrollment status: $_isEnrolled');
    } catch (e) {
      setState(() {
        _error = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Method to view files
  Future<void> _viewFile(CourseMaterial material) async {
    try {
      if (material.type == 'note' && material.content != null) {
        // Show note content in a dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(material.title, style: GoogleFonts.poppins()),
            content: SingleChildScrollView(
              child: Text(material.content!, style: GoogleFonts.poppins()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Close', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        );
      } else if (material.type == 'link' && material.externalUrl != null) {
        // Open external URL
        if (await canLaunchUrl(Uri.parse(material.externalUrl!))) {
          await launchUrl(Uri.parse(material.externalUrl!), mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the URL')),
          );
        }
      } else if (material.fileUrl != null) {
        // Open file URL
        if (await canLaunchUrl(Uri.parse(material.fileUrl!))) {
          await launchUrl(Uri.parse(material.fileUrl!), mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the file')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No content available to view')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: ${e.toString()}')),
      );
    }
  }

  void _showPaymentPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Premium Content', style: GoogleFonts.poppins()),
        content: Text(
          'You need to enroll in this course to access the materials. Would you like to proceed to payment?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF60A5FA), // Accent Color 1
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed(
                '/courses/payment',
                arguments: {'course': _course},
              );
            },
            child: Text('Proceed to Payment', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  // Helper method to get icon for material type
  IconData _getMaterialIcon(String type) {
    switch (type) {
      case 'note':
        return Icons.note;
      case 'document':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_library;
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Helper method to get color for material type
  Color _getMaterialColor(String type) {
    switch (type) {
      case 'note':
        return Color(0xFF60A5FA); // Accent Color 1
      case 'document':
        return Color(0xFFC084FC); // Accent Color 2
      case 'image':
        return Colors.green;
      case 'video':
        return Colors.purple;
      case 'link':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Course Details', style: GoogleFonts.poppins()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Course Details', style: GoogleFonts.poppins()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text('Error', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF60A5FA)), // Accent Color 1
                  child: Text('Go Back', style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Course Details', style: GoogleFonts.poppins()),
        ),
        body: Center(child: Text('Course not found', style: GoogleFonts.poppins())),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_course!.title, style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: isDark ? Color(0xFF161B22) : Color(0xFFF9FAFB), // Card Background
              child: Center(
                child: Icon(Icons.book, size: 80, color: theme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _course!.title,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Color(0xFFE4E4E7) : Color(0xFF1F2937)), // Text - Primary
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Grade ${_course!.grade}',
                    style: GoogleFonts.poppins(color: theme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('by ${_course!.teacherName ?? 'Unknown Teacher'}',
                style: GoogleFonts.poppins(fontSize: 16, color: isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563))), // Text - Secondary
            const SizedBox(height: 16),
            Row(
              children: [
                Text('\$${_course!.price.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                if (_isEnrolled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981).withOpacity(0.2), // Success/Green
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Color(0xFF10B981)), // Success/Green
                    ),
                    child: Text('Enrolled',
                        style: GoogleFonts.poppins(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('About This Course', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_course!.description, style: GoogleFonts.poppins(fontSize: 16)),
            const SizedBox(height: 24),
            if (!_isEnrolled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/courses/payment',
                      arguments: {'course': _course},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF60A5FA), // Accent Color 1
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Enroll Now', style: GoogleFonts.poppins(fontSize: 16)),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Course Materials',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                if (!_isEnrolled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFF97316).withOpacity(0.2), // Info/Blue
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Color(0xFFF97316)), // Info/Blue
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 16, color: Color(0xFFF97316)),
                        const SizedBox(width: 4),
                        Text('Premium Content',
                            style: GoogleFonts.poppins(
                                color: Color(0xFFF97316),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_materials.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text('No materials available for this course',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                ),
              )
            else
              Column(
                children: List.generate(_materials.length, (index) {
                  final material = _materials[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Stack(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getMaterialColor(material.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getMaterialIcon(material.type),
                              color: _getMaterialColor(material.type),
                              size: 24,
                            ),
                          ),
                          title: Text(material.title, style: GoogleFonts.poppins()),
                          subtitle: Text(material.description, style: GoogleFonts.poppins(fontSize: 13)),
                          trailing: _isEnrolled
                              ? IconButton(
                                  icon: Icon(
                                    Icons.visibility,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: () => _viewFile(material),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.lock, color: Colors.grey),
                                  onPressed: _showPaymentPrompt,
                                ),
                        ),
                        if (!_isEnrolled)
                          Positioned.fill(
                            child: Material(
                              color: Colors.white.withOpacity(0.5),
                              child: InkWell(
                                onTap: _showPaymentPrompt,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock, color: Colors.grey.shade700, size: 24),
                                      const SizedBox(height: 4),
                                      Text('Enroll to Access',
                                          style: GoogleFonts.poppins(
                                              color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
