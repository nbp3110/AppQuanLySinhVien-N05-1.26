import 'package:flutter/material.dart';

import 'screens/project_login_screen.dart';
import 'ui/project_theme.dart';
import 'widgets/firebase_app_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirebaseAppLoader(child: MyApp()));
}

/// Gốc ứng dụng UniNest: chủ đề giao diện và màn hình đăng nhập.
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'UniNest · Quản lý sinh viên',
    theme: projectTheme(),
    home: const ProjectLoginScreen(),
  );
}
