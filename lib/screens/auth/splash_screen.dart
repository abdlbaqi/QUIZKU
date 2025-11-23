// lib/screens/splash_screen.dart
// ignore_for_file: duplicate_import

import 'package:flutter/material.dart';
import 'package:quiz_uas/screens/admin/admin_dashboard_screen.dart';
import 'package:quiz_uas/screens/player/player_dashboard_screen.dart';
import '../../services/firebase_service.dart';   // ← Firebase Service
import 'login_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../player/player_dashboard_screen.dart';  

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Tampilkan splash minimal 3 detik biar cantik
    await Future.delayed(const Duration(seconds: 3));

    // Cek apakah user sudah login di Firebase
    final userData = await FirebaseService.getCurrentUserData();

    // Pastikan widget masih aktif
    if (!mounted) return;

    if (userData != null) {
      // Sudah login → cek role
      final String role = userData['role'] ?? 'pemain';

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PlayerDashboardScreen(userData: userData)),
        );
      }
    } else {
      // Belum login → ke halaman Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea), // biru atas
              Color(0xFF764ba2), // ungu bawah
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo QUIZ! — persis seperti desain awal kamu
            Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Lingkaran ungu dalam
                  Container(
                    width: 175,
                    height: 175,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF9d4edd), Color(0xFF7b2cbf)],
                      ),
                    ),
                  ),
                  // Teks QUIZ!
                  const Text(
                    'QUIZ!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  // Icon tanda tanya
                  const Positioned(
                    top: 35,
                    left: 45,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.question_mark, color: Colors.white, size: 30),
                    ),
                  ),
                  // Icon centang
                  const Positioned(
                    bottom: 35,
                    right: 40,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.check, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),

            // Loading text
            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 25),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 4,
            ),
          ],
        ),
      ),
    );
  }
}