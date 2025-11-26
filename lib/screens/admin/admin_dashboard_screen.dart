// lib/screens/admin/admin_dashboard_screen.dart
// ignore_for_file: duplicate_import

import 'package:flutter/material.dart';
import 'package:quiz_uas/screens/admin/manage_question_screen.dart';
import '../../services/firebase_service.dart';
import '../admin/manage_question_screen.dart';        // ← SUDAH TERHUBUNG!         // ← nanti kalau mau tambah

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
          // Popup Menu (Profil & Pengaturan)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            color: Colors.white,
            onSelected: (value) {
              if (value == "profile") {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profil Admin")),
                );
              } else if (value == "settings") {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pengaturan Admin")),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "profile", child: Row(children: [Icon(Icons.person), SizedBox(width: 10), Text("Profil Admin")])),
              const PopupMenuItem(value: "settings", child: Row(children: [Icon(Icons.settings), SizedBox(width: 10), Text("Pengaturan")])),
            ],
          ),

          // Tombol Logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseService.logout();
              if (!context.mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2c3e50), Color(0xFF34495e)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ADMIN ZONE',
                style: TextStyle(
                  fontSize: 42,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 80),

              // TOMBOL KELOLA SOAL → SUDAH BERFUNGSI!
              _buildAdminButton(
                context,
                icon: Icons.question_answer_outlined,
                label: 'KELOLA SOAL',
                color: Colors.blueAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageQuestionsScreen()),
                  );
                },
              ),

              const SizedBox(height: 40),

              // TOMBOL LIHAT PEMAIN (nanti kalau mau tambah)
              _buildAdminButton(
                context,
                icon: Icons.people_alt,
                label: 'LIHAT SEMUA PEMAIN',
                color: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fitur Daftar Pemain segera hadir!")),
                  );
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => PlayersListScreen()));
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Tombol Admin (cantik & reusable)
  Widget _buildAdminButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 45, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 28),
        elevation: 20,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
      ),
    );
  }
}