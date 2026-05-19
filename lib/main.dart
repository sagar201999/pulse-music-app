import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'views/auth/get_started_screen.dart';
import 'views/main_navigation.dart';
import 'core/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse Music',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: FutureBuilder<bool>(
        future: AuthService().isLoggedIn(),
        builder: (context, snapshot) {
          // While checking token, show a simple black screen or splash
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(backgroundColor: Colors.black);
          }
          
          if (snapshot.data == true) {
            return const MainNavigation();
          } else {
            return const GetStartedScreen();
          }
        },
      ),
    );
  }
}
