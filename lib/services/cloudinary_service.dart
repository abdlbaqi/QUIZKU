// lib/services/cloudinary_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String cloudName = "dgfjnrntx";
  static const String uploadPreset = "fuadmunmun"; 

  static Future<String?> uploadImage({
    File? imageFile,
    Uint8List? webImageBytes,
    String fileName = "question.jpg",
  }) async {
    if (imageFile == null && webImageBytes == null) return null;

    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset;

    if (kIsWeb && webImageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', webImageBytes, filename: fileName));
    } else if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);

      if (response.statusCode == 200) {
        return json['secure_url'] as String;
      } else {
        print('Upload gagal: $respStr');
        return null;
      }
    } catch (e) {
      print('Error Cloudinary: $e');
      return null;
    }
  }
}