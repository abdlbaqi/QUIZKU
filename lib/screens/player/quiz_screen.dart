// lib/screens/player/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import 'package:confetti/confetti.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:ui';

class QuizScreen extends StatefulWidget {
  final String categoryId;
  const QuizScreen({super.key, required this.categoryId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  List<QueryDocumentSnapshot> selectedQuestions = [];
  int currentIndex = 0;
  int score = 0;
  bool isAnswered = false;
  String? selectedAnswer;
  String? correctAnswer;
  bool isLoading = true;
  bool hasError = false;

  // TIMER 15 DETIK
  int timeLeft = 15;
  late AnimationController _timerController;
  late Animation<double> _timerAnimation;

  late AnimationController _scaleAnimation;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _scaleAnimation = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _scaleAnimation, curve: Curves.easeInOut));

    _timerController = AnimationController(vsync: this, duration: const Duration(seconds: 15));
    _timerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _timerController, curve: Curves.linear));

    _timerController.addListener(() {
      setState(() {
        timeLeft = (15 * (1 - _timerAnimation.value)).round();
      });
      if (_timerController.isCompleted && !isAnswered) {
        _nextQuestion();
      }
    });

    _loadQuestions();
  }

  void _startTimer() {
    timeLeft = 15;
    _timerController.reset();
    _timerController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleAnimation.dispose();
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('category', isEqualTo: widget.categoryId)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => hasError = true);
        return;
      }

      final List<QueryDocumentSnapshot> all = snapshot.docs..shuffle();
      setState(() {
        selectedQuestions = all.take(10).toList();
        isLoading = false;
        _startTimer();
      });
    } catch (e) {
      setState(() => hasError = true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _answerQuestion(String answer) {
    if (isAnswered) return;

    setState(() {
      isAnswered = true;
      selectedAnswer = answer;
      correctAnswer = selectedQuestions[currentIndex]['correct_answer']?.toString().toLowerCase().trim();

      if (answer.toLowerCase().trim() == correctAnswer) {
        score += 10;
        _confettiController.play();
      }
    });

    _timerController.stop();
    _scaleAnimation.forward().then((_) => _scaleAnimation.reverse());
  }

  void _nextQuestion() {
    if (currentIndex < selectedQuestions.length - 1) {
      setState(() {
        currentIndex++;
        isAnswered = false;
        selectedAnswer = null;
        correctAnswer = null;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    _confettiController.play();

    final userId = FirebaseService.currentUser?.uid;
    if (userId != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      final snap = await userDoc.get();
      final currentHighScore = snap.data()?['skorTertinggi'] ?? 0;
      if (score > currentHighScore) {
        await userDoc.update({'skorTertinggi': score});
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('SELESAI!', textAlign: TextAlign.center, style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFC107), Color(0xFFFF8F00)]), shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text('Skor Akhir: $score', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAB47BC), padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: const Text('KEMBALI KE MENU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)])),
          child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Colors.white, strokeWidth: 6), SizedBox(height: 30), Text('Memuat soal...', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))])),
        ),
      );
    }

    if (hasError || selectedQuestions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)])),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sentiment_dissatisfied, size: 100, color: Colors.white70),
                const SizedBox(height: 20),
                const Text('Belum ada soal di kategori ini', style: TextStyle(color: Colors.white, fontSize: 22), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF302B63)), child: const Text('Kembali', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
      );
    }

    final data = selectedQuestions[currentIndex].data() as Map<String, dynamic>;
    final String questionText = data['question'] ?? 'Pertanyaan tidak tersedia';
    final String? imageUrl = data['image_url'] as String?;
    final List<String> options = ['a', 'b', 'c', 'd'].map((e) => data['option_$e']?.toString().trim() ?? 'Pilihan $e').toList();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)])),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER: Timer + Progress + Skor
              Padding(
                padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircularPercentIndicator(
                      radius: isTablet ? 55 : 45,
                      lineWidth: 10,
                      percent: _timerAnimation.value,
                      center: Text('$timeLeft', style: TextStyle(fontSize: isTablet ? 32 : 28, fontWeight: FontWeight.bold, color: timeLeft <= 5 ? Colors.red : Colors.white)),
                      progressColor: timeLeft <= 5 ? Colors.red : Colors.amber,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    Text('Soal ${currentIndex + 1}/10', style: TextStyle(color: Colors.white, fontSize: isTablet ? 22 : 20, fontWeight: FontWeight.bold)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 22, vertical: isTablet ? 14 : 12),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFC107), Color(0xFFFF8F00)]), borderRadius: BorderRadius.circular(30)),
                      child: Text('Skor: $score', style: TextStyle(fontSize: isTablet ? 24 : 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),

              // ISI UTAMA — BISA SCROLLABLE
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20, vertical: 10),
                  child: Column(
                    children: [
                      // GAMBAR SOAL — FIT CONTAIN + TIDAK TERPOTONG
                      if (hasImage)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          constraints: const BoxConstraints(maxHeight: 280),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: const Offset(0, 10))]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              loadingBuilder: (c, child, prog) => prog == null ? child : const Center(child: CircularProgressIndicator(color: Colors.white)),
                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.white70)),
                            ),
                          ),
                        ),

                      // PERTANYAAN
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.12)]),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Text(
                          questionText,
                          style: TextStyle(fontSize: isTablet ? 28 : 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // PILIHAN JAWABAN — LEBIH KECIL & MINIMALIS
                      ...List.generate(4, (i) {
                        final letter = String.fromCharCode(65 + i);
                        final optionText = options[i];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: ScaleTransition(
                            scale: _scaleAnim,
                            child: GestureDetector(
                              onTap: () => _answerQuestion(letter.toLowerCase()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isAnswered
                                        ? (letter.toLowerCase() == correctAnswer
                                            ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                                            : letter.toLowerCase() == selectedAnswer
                                                ? [const Color(0xFFE53935), const Color(0xFFEF5350)]
                                                : [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0.1)])
                                        : [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.12)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.2)]),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                                      ),
                                      child: Center(child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(child: Text(optionText, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600))),
                                    if (isAnswered && letter.toLowerCase() == correctAnswer) const Icon(Icons.check_circle, color: Colors.white, size: 32),
                                    if (isAnswered && letter.toLowerCase() == selectedAnswer && selectedAnswer != correctAnswer) const Icon(Icons.cancel, color: Colors.white, size: 32),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 100), // Biar tombol lanjut tidak tertutup
                    ],
                  ),
                ),
              ),

              // TOMBOL LANJUT
              if (isAnswered)
                Container(
                  margin: EdgeInsets.all(isTablet ? 30 : 24),
                  width: double.infinity,
                  height: isTablet ? 80 : 70,
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF302B63),
                      elevation: 25,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                    ),
                    child: Text(currentIndex < 9 ? 'LANJUT' : 'SELESAI', style: TextStyle(fontSize: isTablet ? 26 : 24, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),

      // CONFETTI
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange],
        numberOfParticles: 100,
      ),
    );
  }
}