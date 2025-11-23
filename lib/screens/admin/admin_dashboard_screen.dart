// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
// import 'manage_questions_screen.dart';
// import 'players_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN PANEL'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF2c3e50), Color(0xFF34495e)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ADMIN ZONE',
                style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 60),

              _buildAdminButton(
                context,
                icon: Icons.question_answer,
                label: 'KELOLA SOAL',
                color: Colors.blue,
                // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageQuestionsScreen())),
                onTap: () {},
              ),

              const SizedBox(height: 30),

              _buildAdminButton(
                context,
                icon: Icons.people,
                label: 'LIHAT SEMUA PEMAIN',
                color: Colors.green,
                // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayersListScreen())),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 40),
      label: Text(label, style: const TextStyle(fontSize: 22)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 25),
        elevation: 20,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}