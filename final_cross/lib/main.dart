import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/features/main_screen.dart';
import 'src/features/course/routes.dart';
import 'src/data/repositories/course_repository.dart';
import 'src/features/auth/routes.dart';
import 'src/features/auth/login_pages.dart';
import 'src/features/course/course_list_page.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Final Cross',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/courses': (context) => const CourseListPage(), // Add this route
        '/course-list': (context) => const CourseListPage(), // Add this alternative
      },
      // Add onGenerateRoute for dynamic routes
      onGenerateRoute: (settings) {
        // First try course routes
        final courseRoute = CourseRoutes.build(settings);
        if (courseRoute != null) {
          return courseRoute;
        }
        
        // Then try auth routes
        final authRoute = AuthRoutes.build(settings);
        if (authRoute != null) {
          return authRoute;
        }
        
        // Default route not found
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Text('Route "${settings.name}" not found'),
            ),
          ),
        );
      },
    );
  }
}