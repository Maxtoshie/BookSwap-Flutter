// lib/screens/my_listings_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_edit_book_screen.dart';
import 'chats_screen.dart'; // ← NEW: Import chat screen

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late final User user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Listings & Offers'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Listings'),
              Tab(text: 'Incoming Offers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyListingsTab(user.uid),
            _buildIncomingOffersTab(user.uid),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddEditBookScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // MY LISTINGS TAB
  // ──────────────────────────────────────────────────────────────
  Widget _buildMyListingsTab(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .where('ownerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('You have no listings yet!'));
        }

        final books = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final bookData = books[index].data() as Map<String, dynamic>;
            final bookId = books[index].id;
            final status = bookData['status'] ?? 'available';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: ListTile(
                leading: _buildBookImage(bookData['imageBase64']),
                title: Text(
                  bookData['title'] ?? 'Untitled',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${bookData['author'] ?? 'Unknown'} • $status',
                  style: TextStyle(color: _statusColor(status)),
                ),
                trailing: status == 'available'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddEditBookScreen(bookId: bookId),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, bookId),
                          ),
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: _statusColor(status)),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  // INCOMING OFFERS TAB (with Chat Auto-Open)
  // ──────────────────────────────────────────────────────────────
  Widget _buildIncomingOffersTab(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('swaps')
          .where('receiverId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No incoming swap requests.'));
        }

        final swaps = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: swaps.length,
          itemBuilder: (context, index) {
            final swap = swaps[index].data() as Map<String, dynamic>;
            final swapId = swaps[index].id;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('books')
                  .doc(swap['bookId'])
                  .get(),
              builder: (context, bookSnap) {
                if (!bookSnap.hasData || !bookSnap.data!.exists) {
                  return const SizedBox();
                }
                final book = bookSnap.data!.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: ListTile(
                    leading: _buildBookImage(book['imageBase64']),
                    title: Text(
                      book['title'] ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Status: ${swap['status']}'),
                    trailing: swap['status'] == 'Pending'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => _respondToSwap(
                                    swapId, 'Accepted', book['bookId']),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _respondToSwap(
                                    swapId, 'Rejected', book['bookId']),
                              ),
                            ],
                          )
                        : swap['status'] == 'Accepted'
                            ? TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChatRoomScreen(swapId: swapId),
                                  ),
                                ),
                                child: const Text('Chat'),
                              )
                            : Text(
                                swap['status'],
                                style: TextStyle(
                                  color: swap['status'] == 'Accepted'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  // RESPOND TO SWAP (Auto-Open Chat on Accept)
  // ──────────────────────────────────────────────────────────────
  Future<void> _respondToSwap(
      String swapId, String status, String bookId) async {
    await FirebaseFirestore.instance
        .collection('swaps')
        .doc(swapId)
        .update({'status': status});

    if (status != 'Pending') {
      await FirebaseFirestore.instance
          .collection('books')
          .doc(bookId)
          .update({'status': 'available'});
    }

    // Auto-open chat if accepted
    if (status == 'Accepted' && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(swapId: swapId),
        ),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────
  // DELETE BOOK
  // ──────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(BuildContext context, String bookId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('books').doc(bookId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book deleted')),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────
  // HELPER: Image from Base64
  // ──────────────────────────────────────────────────────────────
  Widget _buildBookImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return const Icon(Icons.book, size: 50);
    }

    try {
      final bytes = base64Decode(base64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 50),
        ),
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 50);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // HELPER: Status Color
  // ──────────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    return switch (status) {
      'available' => Colors.green,
      'pending' => Colors.orange,
      'Accepted' => Colors.green,
      'Rejected' => Colors.red,
      _ => Colors.grey,
    };
  }
}
