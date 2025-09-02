import 'package:flutter/material.dart';
import 'routes.dart';                                // global router
import 'theme.dart';
import 'data/repositories/course_repository.dart';
import 'features/auth/routes.dart';                 // for AuthRoutes.login

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple DI: pass repository into the router (replace with API later)
    final courseRepo = CourseRepository.inMemory();

    return MaterialApp(
      title: 'E-Learning Demo',
      theme: buildTheme(),
      onGenerateRoute: (settings) => buildRoute(settings, courseRepo),
      initialRoute: AuthRoutes.login,                // ✅ use route from auth module
      debugShowCheckedModeBanner: false,
    );
  }
}
