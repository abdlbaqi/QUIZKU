// lib/models/user_model.dart
import 'package:hive/hive.dart';

part 'user_model.g.dart'; // nanti generate dengan flutter pub run build_runner build

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  late String username;

  @HiveField(1)
  late String password;

  @HiveField(2)
  String? namaLengkap;

  User({required this.username, required this.password, this.namaLengkap});
}