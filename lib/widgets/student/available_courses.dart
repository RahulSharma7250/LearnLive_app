import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/course.dart';

const Color primaryPurple = Color(0xFF8852E5);

class AvailableCourses extends StatelessWidget {
  const AvailableCourses({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final availableCourses = courseProvider.availableCourses;

    if (courseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availableCourses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No courses available for your class',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        double screenWidth = constraints.maxWidth;

        if (screenWidth >= 1200) {
          crossAxisCount = 3;
        } else if (screenWidth >= 800) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: availableCourses.length,
          itemBuilder: (ctx, index) {
            return _buildCourseCard(context, availableCourses[index]);
          },
        );
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    final courseProvider = Provider.of<CourseProvider>(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image placeholder
          Container(
            height: 100,
            width: double.infinity,
            color: Colors.indigo.shade100,
            child: Center(
              child: Icon(
                Icons.book,
                size: 48,
                color: primaryPurple,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Grade ${course.grade}',
                    style: const TextStyle(
                      color: primaryPurple,
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
                const SizedBox(height: 4),

                // Teacher name
                Text(
                  'by ${course.teacherName ?? 'Unknown Teacher'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Price
                Text(
                  '\$${course.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    // Explore
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/courses/explore',
                            arguments: {'courseId': course.id},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Explore', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Enroll
                    Expanded(
                      child: ElevatedButton(
                        onPressed: courseProvider.isLoading
                            ? null
                            : () {
                                Navigator.of(context).pushNamed(
                                  '/courses/payment',
                                  arguments: {'course': course},
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Enroll', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
