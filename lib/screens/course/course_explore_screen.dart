import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/course.dart';
import '../../models/course_material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui'; // Add this import for ImageFilter

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
    // Load course details when the screen loads
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
      
      // Fetch course details
      final course = await courseProvider.fetchCourseDetails(authProvider.token, courseId);
      if (course == null) {
        setState(() {
          _error = courseProvider.error ?? 'Failed to load course details';
          _isLoading = false;
        });
        return;
      }
      
      // Check if user is enrolled in this course
      final enrolledCourses = courseProvider.enrolledCourses;
      final isEnrolled = enrolledCourses.any((c) => c.id == courseId);
      
      // Fetch course materials
      final materials = await courseProvider.fetchCourseMaterials(authProvider.token, courseId);
      
      setState(() {
        _course = course;
        _isEnrolled = isEnrolled;
        _materials = materials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _openPdf(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the file')),
      );
    }
  }

  void _showPaymentPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Premium Content'),
        content: const Text('You need to enroll in this course to access the materials. Would you like to proceed to payment?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed(
                '/courses/payment',
                arguments: {'course': _course},
              );
            },
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Course Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Course Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Go Back'),
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
          title: const Text('Course Details'),
        ),
        body: const Center(
          child: Text('Course not found'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_course!.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course header
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.indigo.shade100,
              child: Center(
                child: Icon(
                  Icons.book,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course title and grade
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _course!.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Grade ${_course!.grade}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Teacher name
                  Text(
                    'by ${_course!.teacherName ?? 'Unknown Teacher'}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price and enrollment status
                  Row(
                    children: [
                      Text(
                        '\$${_course!.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_isEnrolled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: const Text(
                            'Enrolled',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Course description
                  const Text(
                    'About This Course',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _course!.description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Enroll button (if not enrolled)
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Enroll Now'),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Course materials
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Course Materials',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isEnrolled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock, size: 16, color: Colors.orange.shade800),
                              const SizedBox(width: 4),
                              Text(
                                'Premium Content',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (_materials.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'No materials available for this course',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Add a header explaining the materials access
                        if (!_isEnrolled)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Enroll in this course to access all materials',
                                    style: TextStyle(color: Colors.orange.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _materials.length,
                          itemBuilder: (ctx, index) {
                            final material = _materials[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Stack(
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      material.type == 'pdf' ? Icons.picture_as_pdf : Icons.note,
                                      color: material.type == 'pdf' ? Colors.red : Colors.blue,
                                    ),
                                    title: Text(material.title),
                                    subtitle: Text(material.description),
                                    trailing: _isEnrolled
                                        ? IconButton(
                                            icon: const Icon(Icons.download),
                                            onPressed: () {
                                              if (material.fileUrl != null) {
                                                _openPdf(material.fileUrl!);
                                              } else if (material.content != null) {
                                                // Show note content in a dialog
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: Text(material.title),
                                                    content: SingleChildScrollView(
                                                      child: Text(material.content!),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(ctx).pop();
                                                        },
                                                        child: const Text('Close'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                            },
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.lock, color: Colors.grey),
                                            onPressed: _showPaymentPrompt,
                                          ),
                                  ),
                                  // Overlay for non-enrolled users
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
                                                Icon(
                                                  Icons.lock,
                                                  color: Colors.grey.shade700,
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Enroll to Access',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

