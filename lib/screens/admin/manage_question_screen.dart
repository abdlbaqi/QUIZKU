// lib/screens/admin/manage_questions.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui';
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
  File? _selectedImage;
  Uint8List? _webImageBytes;
  String? _currentImageUrl;
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

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _webImageBytes = null;
      if (_currentImageUrl != null) _removeExistingImage = true;
      _currentImageUrl = null;
    });
  }

  Future<String?> _uploadImageIfAny() async {
    try {
      if (_removeExistingImage && _selectedImage == null && _webImageBytes == null) {
        return null;
      }

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
        return _currentImageUrl;
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
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

  // Glass Container Widget
  Widget _buildGlassContainer({
    required Widget child,
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    Widget? imagePreview;
    if (_webImageBytes != null) {
      imagePreview = Image.memory(_webImageBytes!, fit: BoxFit.contain, height: 200);
    } else if (!kIsWeb && _selectedImage != null) {
      imagePreview = Image.file(_selectedImage!, fit: BoxFit.contain, height: 200);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imagePreview = Image.network(
        _currentImageUrl!,
        fit: BoxFit.contain,
        height: 200,
        loadingBuilder: (context, child, progress) => progress == null 
            ? child 
            : const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: Colors.white70),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366f1),
              const Color(0xFF8b5cf6),
              const Color(0xFFec4899),
            ].map((c) => c.withOpacity(0.3)).toList(),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header dengan Glass Effect
              _buildGlassContainer(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.quiz, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Kelola Soal Kuis',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: isDesktop ? _buildDesktopLayout(imagePreview) : _buildMobileLayout(imagePreview),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Widget? imagePreview) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form Section
        Expanded(
          flex: 3,
          child: _buildFormSection(imagePreview),
        ),
        const SizedBox(width: 16),
        // List Section
        Expanded(
          flex: 2,
          child: _buildListSection(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Widget? imagePreview) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFormSection(imagePreview),
          const SizedBox(height: 16),
          SizedBox(
            height: 500,
            child: _buildListSection(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFormSection(Widget? imagePreview) {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Edit Soal' : 'Tambah Soal',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Kategori
              _buildGlassField(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF1a1a2e),
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.category, color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: categoryOptions
                      .map((e) => DropdownMenuItem(
                            value: e['value'],
                            child: Text(e['label']!, style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
              const SizedBox(height: 16),

              // Image Upload
              const Text('Gambar Soal (Opsional)', 
                  style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildGlassButton(
                      onPressed: _pickImage,
                      icon: Icons.add_photo_alternate,
                      label: 'Pilih Gambar',
                      color: const Color(0xFF3b82f6),
                    ),
                  ),
                  if (_selectedImage != null || _webImageBytes != null || _currentImageUrl != null) ...[
                    const SizedBox(width: 12),
                    _buildGlassButton(
                      onPressed: _removeImage,
                      icon: Icons.delete_outline,
                      label: '',
                      color: const Color(0xFFef4444),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Image Preview
              if (imagePreview != null)
                _buildGlassContainer(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imagePreview,
                  ),
                ),

              // Pertanyaan
              _buildGlassField(
                child: TextFormField(
                  controller: _questionCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Pertanyaan',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.question_answer, color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Options A-D
              ...['A', 'B', 'C', 'D'].asMap().entries.map((e) {
                final ctrl = [_aCtrl, _bCtrl, _cCtrl, _dCtrl][e.key];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildGlassField(
                    child: TextFormField(
                      controller: ctrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Pilihan ${e.value}',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        border: InputBorder.none,
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),
              const Text('Jawaban Benar', 
                  style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              
              // Radio Buttons
              _buildGlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['a', 'b', 'c', 'd'].map((opt) {
                    final isSelected = _correctAnswer == opt;
                    return GestureDetector(
                      onTap: () => setState(() => _correctAnswer = opt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          opt.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _buildGlassButton(
                  onPressed: _isSaving ? null : _saveQuestion,
                  icon: _isEditing ? Icons.update : Icons.save,
                  label: _isSaving 
                      ? 'Menyimpan...' 
                      : (_isEditing ? 'Update Soal' : 'Simpan Soal'),
                  color: _isEditing 
                      ? const Color(0xFFf59e0b)
                      : const Color(0xFF10b981),
                  isLoading: _isSaving,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListSection() {
    return _buildGlassContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Row(
              children: [
                Icon(Icons.list_alt, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Daftar Soal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('questions')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada soal',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    final img = data['image_url'] as String?;

                    return _buildGlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Image or Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: img != null && img.isNotEmpty
                                  ? Image.network(
                                      img,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => 
                                          const Icon(Icons.broken_image, color: Colors.white70),
                                    )
                                  : const Icon(Icons.quiz, color: Colors.white70, size: 30),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['question'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        (data['category'] ?? 'umum').toString().toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '✓ ${(data['correct_answer'] ?? '').toString().toUpperCase()}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Actions
                          Column(
                            children: [
                              IconButton(
                                onPressed: () => _editQuestion(docs[i]),
                                icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              IconButton(
                                onPressed: () => _deleteQuestion(docId),
                                icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.3),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      icon: isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Icon(icon, size: 20),
      label: label.isNotEmpty ? Text(label, style: const TextStyle(fontWeight: FontWeight.w600)) : const SizedBox(),
    );
  }
}