import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _myBooks = [];

  List<Map<String, dynamic>> get myBooks => _myBooks;

  void listenToMyBooks() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('books')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      _myBooks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addBook({
    required String title,
    required String author,
    required String condition,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('books').add({
      'title': title,
      'author': author,
      'condition': condition,
      'ownerId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBook({
    required String bookId,
    required String title,
    required String author,
    required String condition,
  }) async {
    await _firestore.collection('books').doc(bookId).update({
      'title': title,
      'author': author,
      'condition': condition,
    });
  }

  Future<void> deleteBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).delete();
  }
}
