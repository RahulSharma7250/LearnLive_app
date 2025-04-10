import 'package:flutter/material.dart';
import 'package:my_app/screens/teacher/course_materials_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/teacher/teacher_upcoming_sessions.dart';
import '../../widgets/teacher/teacher_courses.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  bool _isInit = true;
  bool _isLoading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _fetchData();
      _isInit = false;
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);

      await Future.wait([
        courseProvider.fetchAvailableCourses(authProvider.token, null),
        courseProvider.fetchUpcomingSessions(authProvider.token),
      ]);

      if (courseProvider.error != null) {
        setState(() {
          _error = courseProvider.error;
        });
        courseProvider.clearError();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final courseProvider = Provider.of<CourseProvider>(context);

    final teacherId = user?.id;
    final teacherCourses = courseProvider.availableCourses
        .where((course) => course.teacherId == teacherId)
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Color(0xFF0D1117) : Color(0xFFFFFFFF); // ✅ Background
    final cardColor = isDark ? Color(0xFF161B22) : Color(0xFFF9FAFB); // ✅ Card
    final primaryText = isDark ? Color(0xFFE4E4E7) : Color(0xFF1F2937); // ✅ Headings
    final secondaryText = isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563); // ✅ Subtext
    final borderColor = isDark ? Color(0xFF2A2E35) : Color(0xFFE5E7EB); // ✅ Borders
    final errorBg = isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade100; // ✅ Error background
    final errorBorder = isDark ? Colors.red.shade800 : Colors.red.shade300; // ✅ Error border
    final errorText = isDark ? Colors.red.shade200 : Colors.red.shade800; // ✅ Error text

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Teacher Dashboard', style: TextStyle(color: primaryText)),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryText), // ✅ icon color
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'create_session',
            onPressed: () {
              Navigator.of(context).pushNamed('/sessions/create');
            },
            backgroundColor: Color(0xFF3A8DFF), // ✅ Primary Gradient 1
            child: const Icon(Icons.video_call, color: Colors.white),
            tooltip: 'Create Session',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create_course',
            onPressed: () {
              Navigator.of(context).pushNamed('/courses/create');
            },
            backgroundColor: Color(0xFFA259FF), // ✅ Primary Gradient 2
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Create Course',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: errorBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: errorBorder),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: errorText),
                        ),
                      ),
                    Text(
                      'Welcome, ${user?.name ?? 'Teacher'}!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your courses and sessions',
                      style: TextStyle(color: secondaryText),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: borderColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.book, color: Color(0xFF60A5FA)), // ✅ Accent 1
                                  const SizedBox(height: 8),
                                  Text(
                                    '${teacherCourses.length}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Active Courses', style: TextStyle(color: secondaryText)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: borderColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.people, color: Color(0xFFC084FC)), // ✅ Accent 2
                                  const SizedBox(height: 8),
                                  Text(
                                    '${teacherCourses.fold(0, (sum, course) => sum + (course.students?.length ?? 0))}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Total Students', style: TextStyle(color: secondaryText)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Upcoming Live Sessions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/sessions/create');
                          },
                          icon: Icon(Icons.add, color: Color(0xFF60A5FA)), // ✅ Accent
                          label: Text('New Session', style: TextStyle(color: Color(0xFF60A5FA))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const TeacherUpcomingSessions(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Courses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            if (teacherCourses.isNotEmpty) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CourseMaterialsScreen(courseId: teacherCourses[0].id),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Create a course first to manage materials')),
                              );
                            }
                          },
                          icon: Icon(Icons.book, color: Color(0xFFC084FC)),
                          label: Text('Manage Materials', style: TextStyle(color: Color(0xFFC084FC))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const TeacherCourses(),
                  ],
                ),
              ),
            ),
    );
  }
}
