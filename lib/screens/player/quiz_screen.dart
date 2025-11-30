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
        backgroundColor: Colors.white,
        title: const Text('SELESAI!', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.purple)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
            const SizedBox(height: 20),
            Text('Skor Akhir: $score', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.purple)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('KEMBALI KE MENU', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF667eea),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 6),
              SizedBox(height: 30),
              Text('Memuat soal...', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (hasError || selectedQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF667eea),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sentiment_dissatisfied, size: 100, color: Colors.white70),
              const SizedBox(height: 20),
              const Text('Belum ada soal di kategori ini', style: TextStyle(color: Colors.white, fontSize: 22), textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF667eea)),
                child: const Text('Kembali', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
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
          child: Column(
            children: [
              // Header - Progress & Skor
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                      child: Text('Soal ${currentIndex + 1}/10', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(25)),
                      child: Text('Skor: $score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // GAMBAR SOAL - TIDAK TERPOTONG LAGI!
              if (imageUrl != null && imageUrl.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain, // INI YANG PENTING! Gambar utuh tidak terpotong
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) =>
                          loadingProgress == null ? child : const Center(child: CircularProgressIndicator(color: Colors.purple)),
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey)),
                    ),
                  ),
                ),
              if (imageUrl != null && imageUrl.isNotEmpty) const SizedBox(height: 25),

              // PERTANYAAN - TEXT JELAS & SCROLLABLE
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      questionText,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // PILIHAN JAWABAN - CANTIK & JELAS
              Expanded(
                flex: 3,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 4,
                  itemBuilder: (context, i) {
                    final letter = String.fromCharCode(65 + i);
                    final optionText = options[i];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: GestureDetector(
                          onTap: () => _answerQuestion(letter.toLowerCase()),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isAnswered
                                  ? (letter.toLowerCase() == correctAnswer
                                      ? Colors.green.withOpacity(0.9)
                                      : letter.toLowerCase() == selectedAnswer
                                          ? Colors.red.withOpacity(0.9)
                                          : Colors.white.withOpacity(0.2))
                                  : Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.black87,
                                  child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (isAnswered && letter.toLowerCase() == correctAnswer)
                                  const Icon(Icons.check_circle, color: Colors.white, size: 40),
                                if (isAnswered && letter.toLowerCase() == selectedAnswer && selectedAnswer != correctAnswer)
                                  const Icon(Icons.cancel, color: Colors.white, size: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // TOMBOL LANJUT
              if (isAnswered)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF667eea),
                        elevation: 20,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                      ),
                      child: Text(
                        currentIndex < 9 ? 'SOAL BERIKUTNYA' : 'LIHAT HASIL',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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