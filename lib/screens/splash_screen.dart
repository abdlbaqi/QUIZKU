// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Pindah ke halaman berikutnya setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Nanti kita ganti jadi halaman username
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PlaceholderScreen()),
        );
      }
    });
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
            // === LOGO LINGKARAN PUTIH ===
            Container(
              width: 200,
              height: 200,
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
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF9d4edd),
                          Color(0xFF7b2cbf),
                        ],
                      ),
                    ),
                  ),

                  // Teks QUIZ!
                  const Text(
                    'QUIZ!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  // Icon tanda tanya (kiri atas)
                  const Positioned(
                    top: 30,
                    left: 40,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.question_mark, color: Colors.white, size: 28),
                    ),
                  ),

                  // Icon centang (kanan bawah)
                  const Positioned(
                    bottom: 40,
                    right: 30,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.check, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),

            // Loading text
            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            // Indikator loading
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// Sementara buat placeholder biar ga error
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Splash selesai!\nSekarang lanjut halaman berikutnya',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.black54),
        ),
      ),
    );
  }
}