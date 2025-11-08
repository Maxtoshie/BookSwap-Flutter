// lib/screens/add_edit_book_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // ← kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart'; // ← Web support
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditBookScreen extends StatefulWidget {
  final String? bookId;
  const AddEditBookScreen({super.key, this.bookId});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '', _author = '', _condition = 'Good';
  Uint8List? _imageBytes;
  String? _imageBase64;
  bool _isUploading = false;
  bool _isEditMode = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.bookId != null;
    if (_isEditMode) _loadBookData();
  }

  Future<void> _loadBookData() async {
    final doc = await FirebaseFirestore.instance
        .collection('books')
        .doc(widget.bookId)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    setState(() {
      _title = data['title'] ?? '';
      _author = data['author'] ?? '';
      _condition = data['condition'] ?? 'Good';
      _imageBase64 = data['imageBase64'] as String?;
      if (_imageBase64 != null) {
        _imageBytes = base64Decode(_imageBase64!);
      }
    });
  }

  // ──────────────────────────────────────────────────────────────
  // PICK IMAGE: Web vs Mobile
  // ──────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    setState(() => _isUploading = true);

    try {
      if (kIsWeb) {
        // ── WEB: Use image_picker_web ───────────────────────────
        final pickedFile = await ImagePickerWeb.getImageAsBytes();
        if (pickedFile != null) {
          final base64 = base64Encode(pickedFile);
          if (base64.length > 150 * 1024) {
            _showError('Image too large. Max 100 KB.');
            return;
          }
          setState(() {
            _imageBytes = pickedFile;
            _imageBase64 = base64;
          });
        }
      } else {
        // ── MOBILE: Use image_picker + compress ─────────────────
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 70,
        );

        if (image == null) return;

        final compressed = await FlutterImageCompress.compressWithFile(
          image.path,
          minWidth: 800,
          minHeight: 800,
          quality: 85,
          format: CompressFormat.jpeg,
        );

        if (compressed != null) {
          final base64 = base64Encode(compressed);
          if (base64.length > 150 * 1024) {
            _showError('Image too large. Max 100 KB after compression.');
            return;
          }
          setState(() {
            _imageBytes = compressed;
            _imageBase64 = base64;
          });
        }
      }
    } catch (e) {
      _showError('Image processing failed: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // SUBMIT: Add or Edit
  // ──────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_imageBase64 == null) {
      _showError('Please select an image');
      return;
    }

    setState(() => _isUploading = true);

    try {
      if (_isEditMode) {
        // ── EDIT MODE ─────────────────────────────────────
        await FirebaseFirestore.instance
            .collection('books')
            .doc(widget.bookId)
            .update({
          'title': _title,
          'author': _author,
          'condition': _condition,
          'imageBase64': _imageBase64,
        });
      } else {
        // ── ADD MODE ──────────────────────────────────────
        await FirebaseFirestore.instance.collection('books').add({
          'title': _title,
          'author': _author,
          'condition': _condition,
          'imageBase64': _imageBase64,
          'ownerId': FirebaseAuth.instance.currentUser!.uid,
          'status': 'available',
          'createdAt': FieldValue.serverTimestamp(), // ← Correct: inside .add()
        });
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Book' : 'Post a Book'),
        backgroundColor: theme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── IMAGE PREVIEW ─────────────────────────────────
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 50),
                          ),
                        )
                      : const Icon(Icons.add_a_photo,
                          size: 50, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              // ── FORM FIELDS ───────────────────────────────────
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: 'Book Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _title = v!,
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _author,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _author = v!,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _condition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: ['New', 'Like New', 'Good', 'Fair', 'Poor']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _condition = v!),
              ),
              const SizedBox(height: 24),

              // ── SUBMIT BUTTON ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Saving...'),
                          ],
                        )
                      : Text(_isEditMode ? 'Update Book' : 'Post Book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
