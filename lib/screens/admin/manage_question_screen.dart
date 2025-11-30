// lib/screens/admin/manage_questions.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
// ignore: unused_import
import 'package:http/http.dart' as http;

// Cloudinary Service – pastikan file ini ada di lib/services/cloudinary_service.dart
import '../../services/cloudinary_service.dart';

class ManageQuestionsScreen extends StatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _aCtrl = TextEditingController();
  final _bCtrl = TextEditingController();
  final _cCtrl = TextEditingController();
  final _dCtrl = TextEditingController();

  String _correctAnswer = 'a';
  String _selectedCategory = 'umum';
  bool _isEditing = false;
  String? _editingDocId;

  // Image states
  File? _selectedImage;           // mobile
  Uint8List? _webImageBytes;      // web
  String? _currentImageUrl;       // URL dari Firestore
  bool _removeExistingImage = false;

  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> categoryOptions = [
    {'value': 'matematika', 'label': 'Matematika'},
    {'value': 'hewan', 'label': 'Hewan'},
    {'value': 'olahraga', 'label': 'Olahraga'},
    {'value': 'umum', 'label': 'Umum'},
  ];

  @override
  void dispose() {
    _questionCtrl.dispose();
    _aCtrl.dispose();
    _bCtrl.dispose();
    _cCtrl.dispose();
    _dCtrl.dispose();
    super.dispose();
  }

  // Pilih gambar
  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _selectedImage = null;
          _currentImageUrl = null;
          _removeExistingImage = false;
        });
      } else {
        setState(() {
          _selectedImage = File(picked.path);
          _webImageBytes = null;
          _currentImageUrl = null;
          _removeExistingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Hapus gambar dari UI
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _webImageBytes = null;
      if (_currentImageUrl != null) _removeExistingImage = true;
      _currentImageUrl = null;
    });
  }

  // Upload ke Cloudinary (jika ada gambar baru)
  Future<String?> _uploadImageIfAny() async {
    try {
      // Hapus gambar & tidak ada gambar baru → return null
      if (_removeExistingImage && _selectedImage == null && _webImageBytes == null) {
        return null;
      }

      // Tidak ada gambar baru → pakai URL lama
      if (_selectedImage == null && _webImageBytes == null) {
        return _currentImageUrl;
      }

      final String? uploadedUrl = await CloudinaryService.uploadImage(
        imageFile: !kIsWeb ? _selectedImage : null,
        webImageBytes: kIsWeb ? _webImageBytes : null,
        fileName: 'soal_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (uploadedUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal upload ke Cloudinary'), backgroundColor: Colors.red),
          );
        }
        return _currentImageUrl; // fallback
      }
      return uploadedUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error upload: $e'), backgroundColor: Colors.red),
        );
      }
      return _currentImageUrl;
    }
  }

  // Simpan / Update soal
  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Menyimpan...')));

    try {
      final String? imageUrl = await _uploadImageIfAny();

      final data = {
        'question': _questionCtrl.text.trim(),
        'option_a': _aCtrl.text.trim(),
        'option_b': _bCtrl.text.trim(),
        'option_c': _cCtrl.text.trim(),
        'option_d': _dCtrl.text.trim(),
        'correct_answer': _correctAnswer,
        'category': _selectedCategory,
        'image_url': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing && _editingDocId != null) {
        await FirebaseFirestore.instance.collection('questions').doc(_editingDocId).update(data);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(const SnackBar(content: Text('Soal berhasil diperbarui!'), backgroundColor: Colors.green));
      } else {
        await FirebaseFirestore.instance.collection('questions').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(const SnackBar(content: Text('Soal berhasil ditambahkan!'), backgroundColor: Colors.green));
      }

      _clearForm();
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _editQuestion(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _questionCtrl.text = data['question'] ?? '';
    _aCtrl.text = data['option_a'] ?? '';
    _bCtrl.text = data['option_b'] ?? '';
    _cCtrl.text = data['option_c'] ?? '';
    _dCtrl.text = data['option_d'] ?? '';
    _correctAnswer = data['correct_answer'] ?? 'a';
    _selectedCategory = data['category'] ?? 'umum';
    _currentImageUrl = data['image_url'];
    _selectedImage = null;
    _webImageBytes = null;
    _removeExistingImage = false;
    _isEditing = true;
    _editingDocId = doc.id;
    setState(() {});
  }

  Future<void> _deleteQuestion(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Soal?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Soal ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('questions').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Soal berhasil dihapus!'), backgroundColor: Colors.orange),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    _questionCtrl.clear();
    _aCtrl.clear();
    _bCtrl.clear();
    _cCtrl.clear();
    _dCtrl.clear();
    _correctAnswer = 'a';
    _selectedCategory = 'umum';
    _selectedImage = null;
    _webImageBytes = null;
    _currentImageUrl = null;
    _removeExistingImage = false;
    _isEditing = false;
    _editingDocId = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget? imagePreview;
    if (_webImageBytes != null) {
      imagePreview = Image.memory(_webImageBytes!, fit: BoxFit.contain, height: 250);
    } else if (!kIsWeb && _selectedImage != null) {
      imagePreview = Image.file(_selectedImage!, fit: BoxFit.contain, height: 250);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imagePreview = Image.network(
        _currentImageUrl!,
        fit: BoxFit.contain,
        height: 250,
        loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Colors.purple)),
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80, color: Colors.red),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Soal Kuis'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 10,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF16213e)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // ==================== FORM ====================
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 15,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: Colors.white),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_isEditing ? 'Edit Soal' : 'Tambah Soal Baru',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.purple)),
                            const Divider(thickness: 2, color: Colors.purple),
                            const SizedBox(height: 20),

                            // Kategori
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Kategori',
                                prefixIcon: const Icon(Icons.category, color: Colors.purple),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                                filled: true,
                                fillColor: Colors.purple[50],
                              ),
                              items: categoryOptions
                                  .map((e) => DropdownMenuItem(value: e['value'], child: Text(e['label']!)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedCategory = v!),
                            ),
                            const SizedBox(height: 20),

                            // Upload Gambar
                            const Text('Gambar Soal (Opsional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Pilih Gambar'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                ),
                                const SizedBox(width: 10),
                                if (_selectedImage != null || _webImageBytes != null || _currentImageUrl != null)
                                  ElevatedButton.icon(
                                    onPressed: _removeImage,
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Hapus'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Preview Gambar
                            if (imagePreview != null)
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(maxHeight: 300),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.purple, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                                ),
                                child: ClipRRect(borderRadius: BorderRadius.circular(18), child: imagePreview),
                              ),
                            if (imagePreview != null) const SizedBox(height: 25),

                            // Pertanyaan
                            TextFormField(
                              controller: _questionCtrl,
                              decoration: InputDecoration(
                                labelText: 'Pertanyaan',
                                prefixIcon: const Icon(Icons.question_answer),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              maxLines: 5,
                              validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: 15),

                            // Pilihan A-D
                            ...['A', 'B', 'C', 'D'].asMap().entries.map((e) {
                              final ctrl = [_aCtrl, _bCtrl, _cCtrl, _dCtrl][e.key];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: TextFormField(
                                  controller: ctrl,
                                  decoration: InputDecoration(
                                    labelText: 'Pilihan ${e.value}',
                                    prefixIcon: CircleAvatar(
                                        backgroundColor: Colors.purple,
                                        child: Text(e.value, style: const TextStyle(color: Colors.white))),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                                    filled: true,
                                    fillColor: Colors.purple[50],
                                  ),
                                  validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                                ),
                              );
                            }),

                            const SizedBox(height: 20),
                            const Text('Jawaban Benar:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(
                              children: ['a', 'b', 'c', 'd'].map((opt) {
                                return Row(
                                  children: [
                                    Radio<String>(
                                      value: opt,
                                      groupValue: _correctAnswer,
                                      onChanged: (v) => setState(() => _correctAnswer = v!),
                                      activeColor: Colors.green,
                                    ),
                                    Text(opt.toUpperCase(), style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 20),
                                  ],
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 30),

                            // TOMBOL SIMPAN – SUDAH DIPERBAIKI 100%
                            SizedBox(
                              width: double.infinity,
                              height: 65,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveQuestion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isEditing ? Colors.orange : Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 20,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                                ),
                                child: _isSaving
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Menyimpan...', style: TextStyle(fontSize: 18)),
                                        ],
                                      )
                                    : Text(
                                        _isEditing ? 'UPDATE SOAL' : 'SIMPAN SOAL',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // ==================== LIST SOAL ====================
              Expanded(
                flex: 1,
                child: Card(
                  elevation: 15,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                            color: Colors.redAccent, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                        child: const Center(
                            child: Text('Daftar Soal',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('questions')
                              .orderBy('updatedAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator(color: Colors.purple));
                            }
                            final docs = snapshot.data!.docs;
                            if (docs.isEmpty) {
                              return const Center(child: Text('Belum ada soal', style: TextStyle(fontSize: 18)));
                            }

                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (ctx, i) {
                                final data = docs[i].data() as Map<String, dynamic>;
                                final docId = docs[i].id;
                                final img = data['image_url'] as String?;

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  elevation: 5,
                                  child: ListTile(
                                    leading: img != null && img.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(img, width: 60, height: 60, fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.red)),
                                          )
                                        : const Icon(Icons.quiz, color: Colors.purple, size: 40),
                                    title: Text(data['question'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        'Kategori: ${(data['category'] ?? 'umum').toString().toUpperCase()} | Jawaban: ${(data['correct_answer'] ?? '').toString().toUpperCase()}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editQuestion(docs[i])),
                                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteQuestion(docId)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}