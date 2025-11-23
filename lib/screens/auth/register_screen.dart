// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userCtrl = TextEditingController();

  String _role = 'pemain'; // default
  bool _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    String? error = await FirebaseService.register(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      username: _userCtrl.text,
      role: _role,
    );
    setState(() => _loading = false);

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil! Silakan login')),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    const Text('Daftar Akun', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 50),

                    TextFormField(controller: _userCtrl, decoration: _deco('Username'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                    const SizedBox(height: 20),
                    TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: _deco('Email'), validator: (v) => v!.contains('@') ? null : 'Email tidak valid'),
                    const SizedBox(height: 20),
                    TextFormField(controller: _passCtrl, obscureText: true, decoration: _deco('Password'), validator: (v) => v!.length >= 6 ? null : 'Min 6 karakter'),
                    const SizedBox(height: 30),

                    // // Pilih Role
                    // DropdownButtonFormField<String>(
                    //   value: _role,
                    //   decoration: _deco('Pilih Role'),
                    //   items: const [
                    //     DropdownMenuItem(value: 'pemain', child: Text('Pemain')),
                    //     DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    //   ],
                    //   onChanged: (val) => setState(() => _role = val!),
                    // ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        child: _loading ? const CircularProgressIndicator(color: Colors.purple) : const Text('DAFTAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sudah punya akun? Login', style: TextStyle(color: Colors.white))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      );
}