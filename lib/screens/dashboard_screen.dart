// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class DashboardScreen extends StatelessWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Halo, ${user.namaLengkap ?? user.username}! 👋'),
        backgroundColor: const Color(0xFF7b2cbf),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz, size: 100, color: Color(0xFF7b2cbf)),
            const SizedBox(height: 30),
            Text(
              'Selamat datang di Quiz App!\nKamu sudah login sebagai:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            Text(
              user.username,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7b2cbf)),
            ),
            const SizedBox(height: 50),
            const Text('Halaman kuis, skor, ranking, dll\nakan kita buat selanjutnya ya! 🚀', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}