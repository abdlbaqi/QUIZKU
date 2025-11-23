// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // REGISTER
  static Future<String?> register({
    required String email,
    required String password,
    required String username,
    required String role, // "admin" atau "pemain"
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'username': username,
          'email': email.trim(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null; // sukses
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registrasi gagal';
    } catch (e) {
      return e.toString();
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return {'error': e.message ?? 'Login gagal'};
    }
  }

  // GET CURRENT USER DATA (untuk splash screen)
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    }
    return null;
  }

  // LOGOUT
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // CURRENT USER (untuk cek login)
  static User? get currentUser => _auth.currentUser;
}