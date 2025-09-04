import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/features/main_screen.dart';
import 'src/features/course/routes.dart';
import 'src/data/repositories/course_repository.dart'; // Add this import

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
      onGenerateRoute: (settings) {
        // Create repository instance
        final courseRepo = CourseRepository();
        
        // Handle course routes
        final courseRoute = CourseRoutes.build(settings, courseRepo);
        if (courseRoute != null) {
          return courseRoute;
        }
        
        // Default fallback
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
      },
      home: const AppLauncher(), // changed to a loader-aware widget
    );
  }
}

// Optional wrapper for loading Firebase asynchronously
class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const MainScreen(); // your actual home page
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Firebase Error: ${snapshot.error}'),
            ),
          );
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
