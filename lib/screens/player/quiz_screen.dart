// lib/screens/player/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import 'package:confetti/confetti.dart';
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

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _loadQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
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
    _animationController.forward().then((_) => _animationController.reverse());
  }

  void _nextQuestion() {
    if (currentIndex < selectedQuestions.length - 1) {
      setState(() {
        currentIndex++;
        isAnswered = false;
        selectedAnswer = null;
        correctAnswer = null;
      });
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
        title: const Text(
          'SELESAI!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'Skor Akhir: $score',
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAB47BC),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                'KEMBALI KE MENU',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 6),
                SizedBox(height: 30),
                Text('Memuat soal...', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    }

    if (hasError || selectedQuestions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sentiment_dissatisfied, size: 100, color: Colors.white70),
                const SizedBox(height: 20),
                const Text('Belum ada soal di kategori ini', style: TextStyle(color: Colors.white, fontSize: 22), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF302B63),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Kembali', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = selectedQuestions[currentIndex].data() as Map<String, dynamic>;
    final String questionText = data['question'] ?? 'Pertanyaan tidak tersedia';
    final String? imageUrl = data['image_url'] as String?;
    final List<String> options = ['a', 'b', 'c', 'd']
        .map((e) => data['option_$e']?.toString().trim() ?? 'Pilihan $e')
        .toList();

    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header - Progress & Skor dengan glassmorphism
              Padding(
                padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 12 : 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Text(
                            'Soal ${currentIndex + 1}/10',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 20,
                        vertical: isTablet ? 12 : 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        'Skor: $score',
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content - Scrollable untuk fit semua konten
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.0 : 20.0),
                  child: Column(
                    children: [
                      // GAMBAR SOAL - Tidak terpotong!
                      if (hasImage) ...[
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: isTablet ? 300 : 200,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain, // PENTING: Gambar tidak terpotong!
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) =>
                                  loadingProgress == null
                                      ? child
                                      : Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(40),
                                            child: CircularProgressIndicator(
                                              color: const Color(0xFFAB47BC),
                                              strokeWidth: 4,
                                            ),
                                          ),
                                        ),
                              errorBuilder: (_, __, ___) => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 28 : 24),
                      ],

                      // PERTANYAAN - Jelas & Tidak perlu scroll
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isTablet ? 28.0 : 24.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Text(
                              questionText,
                              style: TextStyle(
                                fontSize: isTablet ? 26 : 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isTablet ? 28 : 24),

                      // PILIHAN JAWABAN - Semua terlihat tanpa scroll
                      ...List.generate(4, (i) {
                        final letter = String.fromCharCode(65 + i);
                        final optionText = options[i];

                        return Padding(
                          padding: EdgeInsets.only(bottom: isTablet ? 18.0 : 16.0),
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: GestureDetector(
                              onTap: () => _answerQuestion(letter.toLowerCase()),
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 22.0 : 18.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isAnswered
                                        ? (letter.toLowerCase() == correctAnswer
                                            ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                                            : letter.toLowerCase() == selectedAnswer
                                                ? [const Color(0xFFE53935), const Color(0xFFEF5350)]
                                                : [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.08)])
                                        : [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: isTablet ? 54 : 50,
                                          height: isTablet ? 54 : 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withOpacity(0.3),
                                                Colors.white.withOpacity(0.2),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.5),
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              letter,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: isTablet ? 26 : 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: isTablet ? 20 : 16),
                                        Expanded(
                                          child: Text(
                                            optionText,
                                            style: TextStyle(
                                              fontSize: isTablet ? 20 : 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                        if (isAnswered && letter.toLowerCase() == correctAnswer)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 36 : 32,
                                          ),
                                        if (isAnswered &&
                                            letter.toLowerCase() == selectedAnswer &&
                                            selectedAnswer != correctAnswer)
                                          Icon(
                                            Icons.cancel_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 36 : 32,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      // Spacing untuk tombol
                      SizedBox(height: isAnswered ? (isTablet ? 20 : 16) : 80),
                    ],
                  ),
                ),
              ),

              // TOMBOL LANJUT - Fixed di bawah
              if (isAnswered)
                Padding(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: isTablet ? 70 : 65,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF302B63),
                        elevation: 20,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                      ),
                      child: Text(
                        currentIndex < 9 ? 'SOAL BERIKUTNYA' : 'LIHAT HASIL',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
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
        emissionFrequency: 0.05,
        numberOfParticles: 100,
      ),
    );
  }
}