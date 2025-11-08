// lib/screens/browse_listings_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BrowseListingsScreen extends StatelessWidget {
  const BrowseListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please sign in to browse',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Listings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .where('status', isEqualTo: 'available')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: theme.primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No books available for swap.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final filtered = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final ownerId = data['ownerId'] as String?;
            return ownerId != null && ownerId != user.uid;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('No books from other users.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final doc = filtered[i];
              final data = doc.data() as Map<String, dynamic>;
              final bookId = doc.id;

              final title = (data['title'] as String?)?.trim() ?? 'Untitled';
              final author = _safeAuthor(data['author']);
              final ts = data['createdAt'] as Timestamp?;
              final timeAgo = ts != null
                  ? DateFormat('d MMM').format(ts.toDate())
                  : 'recently';
              final imageBase64 = data['imageBase64'] as String?;

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: _buildBookImage(imageBase64),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author, style: const TextStyle(color: Colors.grey)),
                      Text('$timeAgo ago',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => _initiateSwap(
                        context, bookId, data['ownerId'] as String, user.uid),
                    child: const Text('Swap'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return const Icon(Icons.book, size: 60);
    }

    try {
      final bytes = base64Decode(base64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: 60,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 60),
        ),
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 60);
    }
  }

  String _safeAuthor(dynamic raw) {
    if (raw == null || raw is! String) return 'Unknown Author';
    final trimmed = raw.trim();
    return trimmed.isEmpty ? 'Unknown Author' : trimmed;
  }

  void _initiateSwap(BuildContext ctx, String bookId, String receiverId,
      String senderId) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Request Swap?'),
        content: const Text('Send swap request to the owner?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send')),
        ],
      ),
    );

    if (ok != true) return;

    await FirebaseFirestore.instance.collection('swaps').add({
      'bookId': bookId,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('books')
        .doc(bookId)
        .update({'status': 'pending'});

    if (!ctx.mounted) return; // ✅ fixed async context issue
    ScaffoldMessenger.of(ctx)
        .showSnackBar(const SnackBar(content: Text('Swap request sent!')));
  }
}
