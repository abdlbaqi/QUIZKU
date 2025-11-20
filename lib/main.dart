// lib/main.dart
import 'package:flutter/material.dart';
import 'package:quiz_uas/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins', // optional, nanti bisa tambah font sendiri
      ),
      home: const SplashScreen(),
    );
  }
}