import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String condition;
  final String imageUrl;
  final String ownerUid;
  final Timestamp createdAt;
  final String status; // available, pending, etc.

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.imageUrl,
    required this.ownerUid,
    required this.createdAt,
    required this.status,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      condition: data['condition'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'author': author,
        'condition': condition,
        'imageUrl': imageUrl,
        'ownerUid': ownerUid,
        'createdAt': createdAt,
        'status': status,
      };
}
