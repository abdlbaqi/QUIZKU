// lib/screens/player/player_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class PlayerDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const PlayerDashboardScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hai, ${userData['username']} 👋'),
        backgroundColor: const Color(0xFF7b2cbf),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",

            // 🔥 LOGOUT BERHASIL
            onPressed: () async {
              await FirebaseService.logout();

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',     // sekarang route ini sudah ada!
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),

        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PEMAIN',
                style: TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Skor Tertinggi: ${userData['skorTertinggi'] ?? 0}',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.amber,
                ),
              ),

              const SizedBox(height: 60),

              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_circle_fill, size: 50),
                label: const Text('MULAI KUIS', style: TextStyle(fontSize: 28)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                  elevation: 15,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.leaderboard, size: 30),
                label: const Text('LEADERBOARD', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
