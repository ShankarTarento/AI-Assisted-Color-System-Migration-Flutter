import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Migration Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Currently using default theme
        // After migration, this will use our generated ThemeData
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
