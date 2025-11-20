// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart'; // penting untuk web & desktop

import 'models/user_model.dart';       // ← User model + adapter
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive untuk semua platform (Android, iOS, Web, Windows, Mac, Linux)
  await Hive.initFlutter();

  // Register Adapter yang sudah di-generate otomatis
  Hive.registerAdapter(UserAdapter());

  // Buka box untuk menyimpan user (bisa dipakai di semua platform)
  await Hive.openBox('userBox');

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
        colorSchemeSeed: const Color(0xFF7b2cbf),
        fontFamily: 'Poppins', // optional, tambah font nanti kalau mau
      ),
      home: const SplashScreen(),
    );
  }
}