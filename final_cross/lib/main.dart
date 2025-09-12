import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/features/main_screen.dart';
import 'src/features/course/routes.dart';
import 'src/data/repositories/course_repository.dart';
import 'src/features/auth/routes.dart';
import 'src/features/auth/login_pages.dart';

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
      onGenerateRoute: (settings) {
        // Create repository instance
        final courseRepo = CourseRepository();
        
        // Handle auth routes first
        final authRoute = AuthRoutes.build(settings);
        if (authRoute != null) {
          return authRoute;
        }
        
        // Handle course routes
        final courseRoute = CourseRoutes.build(settings, courseRepo);
        if (courseRoute != null) {
          return courseRoute;
        }
        
        // Default fallback
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}
