import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/amcl_cls_welcome_screen.dart';
import 'screens/amcl_cls_login_screen.dart';
import 'screens/amcl_cls_register_screen.dart';
import 'screens/amcl_cls_verify_email_screen.dart';
import 'screens/amcl_cls_home_screen.dart';
import 'screens/amcl_cls_create_course_screen.dart';
import 'screens/amcl_cls_course_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduLearn - Caso 1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade700,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/welcome',
      onGenerateRoute: (settings) {
        if (settings.name == '/course-detail') {
          final courseId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => AMCLclsCourseDetailScreen(courseId: courseId),
          );
        }
        return null;
      },
      routes: {
        '/welcome': (context) => const AMCLclsWelcomeScreen(),
        '/login': (context) => const AMCLclsLoginScreen(),
        '/register': (context) => const AMCLclsRegisterScreen(),
        '/verify-email': (context) => const AMCLclsVerifyEmailScreen(),
        '/home': (context) => const AMCLclsHomeScreen(),
        '/create-course': (context) => const AMCLclsCreateCourseScreen(),
      },
    );
  }
}
