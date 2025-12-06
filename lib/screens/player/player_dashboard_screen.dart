// lib/screens/player/player_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import 'category_selection_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart'; // ← FILE BARU UNTUK EDIT PROFIL

class PlayerDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const PlayerDashboardScreen({super.key, required this.userData});

  @override
  State<PlayerDashboardScreen> createState() => _PlayerDashboardScreenState();
}

class _PlayerDashboardScreenState extends State<PlayerDashboardScreen> {
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _userData = Map.from(widget.userData);
  }

  Future<void> _refresh() async {
    final userId = FirebaseService.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists && mounted) {
      setState(() => _userData = doc.data()!);
    }
  }

  Future<void> _logout() async {
    await FirebaseService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 32 : 24),
                    child: Column(
                      children: [
                        // === HEADER ===
                        Row(
                          children: [
                            CircleAvatar(
                              radius: isTablet ? 40 : 32,
                              backgroundImage: _userData['photoURL'] != null
                                  ? NetworkImage(_userData['photoURL'])
                                  : null,
                              child: _userData['photoURL'] == null
                                  ? const Icon(Icons.person, size: 40, color: Colors.white70)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Halo,', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: isTablet ? 22 : 18)),
                                  Text(
                                    _userData['username'] ?? 'Pemain',
                                    style: TextStyle(color: Colors.white, fontSize: isTablet ? 36 : 30, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 50),

                        // === SKOR TERTINGGI ===
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF0091EA)]),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 12))],
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.emoji_events, size: 70, color: Colors.white),
                              const SizedBox(height: 16),
                              const Text('Skor Tertinggi', style: TextStyle(color: Colors.white, fontSize: 20)),
                              Text(
                                '${_userData['skorTertinggi'] ?? 0}',
                                style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 50),

                        // === TOMBOL MULAI KUIS & LEADERBOARD ===
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                title: 'MULAI KUIS',
                                icon: Icons.play_circle,
                                gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategorySelectionScreen())).then((_) => _refresh()),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildActionButton(
                                title: 'LEADERBOARD',
                                icon: Icons.leaderboard_rounded,
                                gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // === AVATAR + LOGOUT DI POJOK KANAN ATAS ===
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 16, right: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logout
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 26),
              tooltip: 'Logout',
            ),
            const SizedBox(width: 8),
            // Profil — Klik buka halaman edit profil
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                if (result == true) {
                  _refresh(); // Refresh kalau ada perubahan
                }
              },
              child: CircleAvatar(
                radius: 22,
                backgroundImage: _userData['photoURL'] != null ? NetworkImage(_userData['photoURL']) : null,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: _userData['photoURL'] == null
                    ? const Icon(Icons.person, color: Colors.white70, size: 26)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 70, color: Colors.white),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}