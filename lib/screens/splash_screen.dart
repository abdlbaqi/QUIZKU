// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../database/hive_helper.dart';        // ← Hive Helper
import '../models/user_model.dart';           // ← User dari Hive
import 'login_screen.dart';
import 'dashboard_screen.dart';

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

    // Cek apakah ada user yang sudah login (dari Hive)
    final user = HiveHelper.getCurrentUser();

    // Pastikan widget masih mounted sebelum navigasi
    if (!mounted) return;

    if (user != null) {
      // Sudah pernah register & login → langsung ke Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
      );
    } else {
      // Belum ada user → ke halaman Login
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
            // Logo QUIZ! (sama persis seperti desain awal kamu)
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