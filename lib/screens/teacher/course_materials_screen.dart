import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/course.dart';
import '../../models/course_material.dart';

// Add file_picker import at the top
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class CourseMaterialsScreen extends StatefulWidget {
  final String? courseId;

  // ignore: use_super_parameters
  const CourseMaterialsScreen({Key? key, this.courseId}) : super(key: key);

  @override
  State<CourseMaterialsScreen> createState() => _CourseMaterialsScreenState();
}

class _CourseMaterialsScreenState extends State<CourseMaterialsScreen> {
  bool _isLoading = true;
  String? _error;
  Course? _course;
  List<CourseMaterial> _materials = [];

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'note'; // 'note' or 'pdf'
  String? _fileUrl;

  // Add a new field to store the selected file
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    // Load course details when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseDetails();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? courseId = widget.courseId;

      if (courseId == null) {
        setState(() {
          _error = 'Course ID not provided';
          _isLoading = false;
        });
        return;
      }

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

      // Fetch course materials
      final materials = await courseProvider.fetchCourseMaterials(authProvider.token, courseId);

      setState(() {
        _course = course;
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

  // Update the _showAddMaterialDialog method to include file picking functionality
  void _showAddMaterialDialog() {
    // Reset form
    _titleController.clear();
    _descriptionController.clear();
    _contentController.clear();
    setState(() {
      _selectedType = 'note';
      _fileUrl = null;
      _selectedFile = null;
    });

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Course Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Material type selection
                const Text('Material Type'),
                Row(
                  children: [
                    Radio<String>(
                      value: 'note',
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const Text('Note'),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: 'pdf',
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const Text('PDF'),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Content (for notes) or File Upload (for PDFs)
                if (_selectedType == 'note')
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Note Content',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Upload PDF File'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _selectedFile != null
                                    ? path.basename(_selectedFile!.path)
                                    : 'No file selected',
                                style: TextStyle(
                                  color: _selectedFile != null ? Colors.black : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf'],
                              );

                              if (result != null) {
                                setDialogState(() {
                                  _selectedFile = File(result.files.single.path!);
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF60A5FA), // Accent Color 1
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Browse'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedFile != null)
                        Text(
                          'File size: ${(_selectedFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF60A5FA), // Accent Color 1
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addMaterial();
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF60A5FA), // Accent Color 1
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Update the _addMaterial method to handle file uploads
  Future<void> _addMaterial() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_selectedType == 'note' && _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter note content')),
      );
      return;
    }

    if (_selectedType == 'pdf' && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);

      String? fileUrl;

      // Upload file if it's a PDF
      if (_selectedType == 'pdf' && _selectedFile != null) {
        // For demo purposes, we'll simulate file upload and generate a fake URL
        // In a real app, you would upload the file to a server or cloud storage
        await Future.delayed(const Duration(seconds: 1)); // Simulate upload time

        // Generate a fake URL for demo purposes
        final fileName = path.basename(_selectedFile!.path);
        fileUrl = 'https://example.com/uploads/$fileName';

        // In a real app, you would do something like this:
        // fileUrl = await uploadFile(_selectedFile!, authProvider.token);
      }

      final material = CourseMaterial(
        id: '', // Will be assigned by the backend
        courseId: _course!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        content: _selectedType == 'note' ? _contentController.text : null,
        fileUrl: fileUrl,
        createdAt: DateTime.now(),
      );

      final success = await courseProvider.addCourseMaterial(authProvider.token, material);

      // Close loading dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (success) {
        // Refresh materials list
        await _loadCourseDetails();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material added successfully'),
            backgroundColor: Color(0xFF10B981), // Success/Green
          ),
        );
      } else {
        setState(() {
          _error = courseProvider.error ?? 'Failed to add material';
        });
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      setState(() {
        _error = 'An error occurred: ${e.toString()}';
      });
    }
  }

  // Add a method to view PDF files
  Future<void> _viewPdf(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the PDF file')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening PDF: ${e.toString()}')),
      );
    }
  }

  // Update the build method to include a better UI for viewing materials
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Course Materials'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Course Materials'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFEF4444), // Error/Red
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: isDark ? Color(0xFFE4E4E7) : Color(0xFF1F2937), // Text - Primary
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF60A5FA), // Accent Color 1
                      ),
                      child: const Text('Go Back'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _loadCourseDetails,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF60A5FA), // Accent Color 1
                      ),
                    ),
                  ],
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
          title: const Text('Course Materials'),
        ),
        body: const Center(
          child: Text('Course not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_course!.title} - Materials'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMaterialDialog,
        backgroundColor: Color(0xFF60A5FA), // Accent Color 1
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course info
            Card(
              color: isDark ? Color(0xFF161B22) : Color(0xFFF9FAFB), // Card Background
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _course!.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF60A5FA), // Accent Color 1
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Grade ${_course!.grade}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF60A5FA), // Accent Color 1
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Materials list
            const Text(
              'Course Materials',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF60A5FA), // Accent Color 1
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _materials.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No materials added yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddMaterialDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Your First Material'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF60A5FA), // Accent Color 1
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _materials.length,
                      itemBuilder: (ctx, index) {
                        final material = _materials[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              if (material.type == 'pdf' && material.fileUrl != null) {
                                _viewPdf(material.fileUrl!);
                              } else if (material.type == 'note' && material.content != null) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(material.title),
                                    content: SingleChildScrollView(
                                      child: Text(material.content!),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: material.type == 'pdf'
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      material.type == 'pdf' ? Icons.picture_as_pdf : Icons.note,
                                      color: material.type == 'pdf' ? Colors.red : Colors.blue,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          material.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF60A5FA), // Accent Color 1
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          material.description,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Added on ${_formatDate(material.createdAt)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    onPressed: () {
                                      // Delete material functionality would go here
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Delete functionality not implemented yet')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Add a helper method to format dates
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
