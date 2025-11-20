// lib/models/user_model.dart
class User {
  final int? id;
  final String username;
  final String password;      // akan kita hash nanti
  final String? namaLengkap;

  User({
    this.id,
    required this.username,
    required this.password,
    this.namaLengkap,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'nama_lengkap': namaLengkap,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      namaLengkap: map['nama_lengkap'],
    );
  }
}