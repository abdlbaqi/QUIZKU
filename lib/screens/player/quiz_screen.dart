// lib/screens/player/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import 'package:confetti/confetti.dart';

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
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('category', isEqualTo: widget.categoryId)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }

      final List<QueryDocumentSnapshot> all = snapshot.docs..shuffle();
      setState(() {
        selectedQuestions = all.take(10).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error loading questions: $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void _answerQuestion(String answer) {
    if (isAnswered) return;

    setState(() {
      isAnswered = true;
      selectedAnswer = answer;
      correctAnswer = selectedQuestions[currentIndex].get('correct_answer')?.toString().trim();

      if (answer.trim() == correctAnswer?.trim()) {
        score += 10;
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
        backgroundColor: Colors.white,
        title: const Text('KEREN!', textAlign: TextAlign.center, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.purple)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
            const SizedBox(height: 20),
            Text('Skor Kamu: $score', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.purple)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('KEMBALI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getOptionColor(String option) {
    if (!isAnswered) return Colors.white.withOpacity(0.25);
    if (option.trim() == correctAnswer?.trim()) return Colors.green.withOpacity(0.9);
    if (option.trim() == selectedAnswer?.trim() && selectedAnswer != correctAnswer) return Colors.red.withOpacity(0.9);
    return Colors.white.withOpacity(0.15);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Loading
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF667eea),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 6),
              SizedBox(height: 25),
              Text('Memuat soal...', style: TextStyle(color: Colors.white, fontSize: 22)),
            ],
          ),
        ),
      );
    }

    // Error / Tidak ada soal
    if (hasError || selectedQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF667eea),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 90, color: Colors.white70),
              const SizedBox(height: 25),
              Text(
                hasError ? 'Gagal memuat soal' : 'Belum ada soal di kategori ini',
                style: const TextStyle(color: Colors.white, fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF7b2cbf)),
                child: const Text('Kembali', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      );
    }

    // AMBIL DATA SOAL DENGAN AMAN
    final Map<String, dynamic> questionData = selectedQuestions[currentIndex].data() as Map<String, dynamic>;
    final String questionText = questionData['question']?.toString() ?? 'Pertanyaan tidak tersedia';
    final String? imageUrl = questionData['image_url']?.toString();
    final List<String> options = ['a', 'b', 'c', 'd']
        .map((opt) => questionData['option_$opt']?.toString() ?? 'Pilihan $opt')
        .toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Progress + Skor
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      label: Text('Soal ${currentIndex + 1}/10', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    Chip(
                      backgroundColor: Colors.amber,
                      label: Text('Skor: $score', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // GAMBAR SOAL — PASTI MUNCUL & SUPER JELAS!
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 25, offset: Offset(0, 12)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.white24,
                            child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 6)),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print("Gambar gagal dimuat: $imageUrl | Error: $error");
                          return Container(
                            color: Colors.white24,
                            child: const Center(child: Icon(Icons.broken_image, size: 90, color: Colors.white70)),
                          );
                        },
                      ),
                    ),
                  ),
                if (imageUrl != null && imageUrl.isNotEmpty) const SizedBox(height: 35),

                // PERTANYAAN
                Expanded(
                  child: Card(
                    elevation: 25,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(35),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), color: Colors.white),
                      child: Center(
                        child: Text(
                          questionText,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                // PILIHAN JAWABAN
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, i) {
                      final optionText = options[i];
                      final letter = String.fromCharCode(65 + i);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: GestureDetector(
                            onTap: () => _answerQuestion(letter.toLowerCase()),
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: _getOptionColor(letter.toLowerCase()),
                                borderRadius: BorderRadius.circular(35),
                                border: Border.all(color: Colors.white, width: 5),
                                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.black87,
                                    child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 30),
                                  Expanded(
                                    child: Text(
                                      optionText,
                                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (isAnswered && letter.toLowerCase() == correctAnswer)
                                    const Icon(Icons.check_circle, color: Colors.white, size: 50),
                                  if (isAnswered && letter.toLowerCase() == selectedAnswer && selectedAnswer != correctAnswer)
                                    const Icon(Icons.cancel, color: Colors.white, size: 50),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // TOMBOL SELANJUTNYA
                if (isAnswered)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: SizedBox(
                      width: double.infinity,
                      height: 75,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF7b2cbf),
                          elevation: 30,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(45)),
                        ),
                        child: Text(
                          currentIndex < 9 ? 'LANJUT' : 'SELESAI KUIS',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
        numberOfParticles: 80,
      ),
    );
  }
}