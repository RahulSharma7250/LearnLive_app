import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/course.dart';
import '../../screens/teacher/course_materials_screen.dart'; // Import the CourseMaterialsScreen

class TeacherCourses extends StatelessWidget {
  const TeacherCourses({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final availableCourses = courseProvider.availableCourses;
    
    if (courseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Filter courses by teacher
    final authProvider = Provider.of<AuthProvider>(context);
    final teacherId = authProvider.user?.id;
    final teacherCourses = availableCourses.where((course) => course.teacherId == teacherId).toList();
    
    if (teacherCourses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'You haven\'t created any courses yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: teacherCourses.length,
      itemBuilder: (ctx, index) {
        return _buildCourseCard(context, teacherCourses[index]);
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image
          Container(
            height: 100,
            color: Colors.indigo.shade100,
            child: Center(
              child: Icon(
                Icons.book,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grade badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Grade ${course.grade}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Course title
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Stats
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${course.students?.length ?? 0} students',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${course.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Manage button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        // Use direct navigation with MaterialPageRoute to ensure proper arguments passing
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CourseMaterialsScreen(courseId: course.id),
                          ),
                        );
                      } catch (e) {
                        // Show error message if navigation fails
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error navigating to course materials: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                     
                        backgroundColor: const Color.fromARGB(255, 136, 82, 229), // 💜 Custom color
                        foregroundColor: Colors.white, // 👈 Text color set to white
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      
                    ),
                    child: const Text('Manage'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

