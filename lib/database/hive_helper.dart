// lib/database/hive_helper.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

class HiveHelper {
  static const String boxName = 'userBox';
  static const String userKey = 'currentUser';

  // Register
  static Future<bool> register(User user) async {
    final box = Hive.box(boxName);
    
    // Cek username sudah ada belum
    final existing = box.values.cast<User?>().any((u) => u?.username == user.username);
    if (existing) return false;

    await box.put(userKey, user);
    return true;
  }

  // Login
  static Future<User?> login(String username, String password) async {
    final box = Hive.box(boxName);
    final user = box.get(userKey) as User?;

    if (user != null && user.username == username && user.password == password) {
      return user;
    }
    return null;
  }

  // Get current user (auto login)
  static User? getCurrentUser() {
    final box = Hive.box(boxName);
    return box.get(userKey) as User?;
  }

  // Logout (hapus user)
  static Future<void> logout() async {
    final box = Hive.box(boxName);
    await box.delete(userKey);
  }
}