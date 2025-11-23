// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import 'register_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../player/player_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await FirebaseService.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result != null && result['error'] == null) {
      // Login berhasil → cek role dan arahkan ke dashboard yang sesuai
      final String role = result['role'] ?? 'pemain';

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PlayerDashboardScreen(userData: result)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['error'] ?? 'Login gagal. Periksa email & password.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: hint.contains('Password')
          ? IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
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
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo QUIZ!
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Color(0xFF9d4edd), Color(0xFF7b2cbf)]),
                        ),
                      ),
                      const Text('QUIZ!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                const Text(
                  'Selamat Datang Kembali!',
                  style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('Masuk untuk melanjutkan kuis', style: TextStyle(color: Colors.white70, fontSize: 16)),

                const SizedBox(height: 40),

                // Email Field
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Email', Icons.email_outlined),
                ),

                const SizedBox(height: 20),

                // Password Field
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Password', Icons.lock_outline),
                ),

                const SizedBox(height: 40),

                // Tombol Login
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7b2cbf),
                      elevation: 10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF7b2cbf))
                        : const Text('MASUK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),

                // Link ke Register
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text(
                    'Belum punya akun? Daftar di sini',
                    style: TextStyle(color: Colors.white, fontSize: 15, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}