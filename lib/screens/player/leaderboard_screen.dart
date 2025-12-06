// lib/screens/player/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard Global'),
        backgroundColor: Color(0xFF302B63),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E)
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('skorTertinggi', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            final users = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final user = users[i].data() as Map<String, dynamic>;
                final isMe = users[i].id == userId;


                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.amber.withOpacity(0.25)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isMe ? Colors.amber : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i < 3 ? Colors.amber : Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: user['photoURL'] != null
                            ? NetworkImage(user['photoURL'])
                            : null,
                        child: user['photoURL'] == null
                            ? const Icon(Icons.person, color: Colors.white70)
                            : null,
                      ),

                      const SizedBox(width: 12),

                      // Username + Penanda (Saya)
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              user['username'] ?? 'Anon',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            if (isMe)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.check_circle,
                                    color: Colors.greenAccent, size: 22),
                              ),

                            if (isMe)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  "(Saya)",
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Score
                      Text(
                        '${user['skorTertinggi'] ?? 0}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Top 3 badge
                      if (i < 3)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            i == 0 ? Icons.emoji_events : Icons.star,
                            color: Colors.amber,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
