import 'package:flutter/material.dart';

import 'screens/project_login_screen.dart';
import 'ui/project_theme.dart';
import 'widgets/firebase_app_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirebaseAppLoader(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'EduSpace · Quản lý sinh viên',
    theme: projectTheme(),
    home: const ProjectLoginScreen(),
  );
}
