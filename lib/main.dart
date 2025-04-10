import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../screens/splash_screen.dart';
import '../../screens/role_selection_screen.dart';
import '../../screens/auth/student_auth_screen.dart';
import '../../screens/auth/teacher_auth_screen.dart';
import '../../screens/student/grade_selection_screen.dart';
import '../../screens/student/student_dashboard.dart';
import '../../screens/teacher/teacher_dashboard.dart';
import '../../screens/teacher/create_course_screen.dart';
import '../../screens/teacher/create_session_screen.dart';
import '../../screens/live_session_screen.dart';
import '../../screens/course/course_explore_screen.dart';
import '../../screens/course/course_payment_screen.dart';
import '../../screens/teacher/course_materials_screen.dart';
import '../../theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CourseProvider>(
          create: (ctx) => CourseProvider(),
          update: (ctx, auth, previousCourseProvider) {
            final courseProvider = previousCourseProvider ?? CourseProvider();
            // Initialize course provider with auth token when available
            if (auth.token != null) {
              courseProvider.initialize(auth.token);
            }
            return courseProvider;
          },
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LearnLive',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: auth.isAuth
              ? auth.user!.role == 'teacher'
                  ? const TeacherDashboard()
                  : auth.user!.classLevel != null
                      ? const StudentDashboard()
                      : const GradeSelectionScreen()
              : FutureBuilder(
                  future: auth.tryAutoLogin(),
                  builder: (ctx, authResultSnapshot) =>
                      authResultSnapshot.connectionState == ConnectionState.waiting
                          ? const SplashScreen()
                          : const RoleSelectionScreen(),
                ),
          routes: {
            // Remove the '/' route since it's redundant with home
            '/student/auth': (ctx) => const StudentAuthScreen(),
            '/teacher/auth': (ctx) => const TeacherAuthScreen(),
            '/student/grade-selection': (ctx) => const GradeSelectionScreen(),
            '/student-dashboard': (ctx) => const StudentDashboard(),
            '/teacher-dashboard': (ctx) => const TeacherDashboard(),
            '/courses/create': (ctx) => const CreateCourseScreen(),
            '/sessions/create': (ctx) => const CreateSessionScreen(),
            '/live-session': (ctx) => const LiveSessionScreen(),
            '/courses/explore': (ctx) => const CourseExploreScreen(),
            '/courses/payment': (ctx) => const CoursePaymentScreen(),
            '/courses/materials': (ctx) => const CourseMaterialsScreen(),
          },
          onGenerateRoute: (settings) {
            // This handles routes with dynamic parameters
            if (settings.name == '/courses/materials') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => CourseMaterialsScreen(courseId: args?['courseId']),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}
