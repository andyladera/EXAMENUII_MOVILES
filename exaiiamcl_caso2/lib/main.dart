import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/amcl_cls_welcome_screen.dart';
import 'screens/amcl_cls_login_screen.dart';
import 'screens/amcl_cls_register_screen.dart';
import 'screens/amcl_cls_home_screen.dart';
import 'screens/amcl_cls_create_survey_screen.dart';

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
      title: 'SurveyApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const AMCLclsWelcomeScreen(),
        '/login': (context) => const AMCLclsLoginScreen(),
        '/register': (context) => const AMCLclsRegisterScreen(),
        '/home': (context) => const AMCLclsHomeScreen(),
        '/create-survey': (context) => const AMCLCreateSurveyScreen(),
      },
    );
  }
}
