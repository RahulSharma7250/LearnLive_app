import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/course.dart';
import '../../models/course_material.dart';

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
      
      // If courseId wasn't passed directly, try to get it from route arguments
      if (courseId == null) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        courseId = args?['courseId'] as String?;
      }
      
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

  void _showAddMaterialDialog() {
    // Reset form
    _titleController.clear();
    _descriptionController.clear();
    _contentController.clear();
    setState(() {
      _selectedType = 'note';
      _fileUrl = null;
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
                
                // Content (for notes) or File URL (for PDFs)
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
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'PDF URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/file.pdf',
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        _fileUrl = value;
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addMaterial();
                Navigator.of(ctx).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

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
    
    if (_selectedType == 'pdf' && (_fileUrl == null || _fileUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a PDF URL')),
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
      
      final material = CourseMaterial(
        id: '', // Will be assigned by the backend
        courseId: _course!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        content: _selectedType == 'note' ? _contentController.text : null,
        fileUrl: _selectedType == 'pdf' ? _fileUrl : null,
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
            backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Go Back'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _loadCourseDetails,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
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
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course info
            Card(
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Grade ${_course!.grade}',
                      style: const TextStyle(
                        fontSize: 16,
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
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _materials.length,
                    itemBuilder: (ctx, index) {
                      final material = _materials[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            material.type == 'pdf' ? Icons.picture_as_pdf : Icons.note,
                            color: material.type == 'pdf' ? Colors.red : Colors.blue,
                          ),
                          title: Text(material.title),
                          subtitle: Text(material.description),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              // Delete material functionality would go here
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Delete functionality not implemented yet')),
                              );
                            },
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
}

