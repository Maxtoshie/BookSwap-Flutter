// lib/screens/chats_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view chats')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('swaps')
            .where('status', isEqualTo: 'Accepted')
            // Replace Filter.or if using older Firestore: you may need to fetch all and filter client-side
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No chats yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Accept a swap to start!',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final seenSwapIds = <String>{};
          final uniqueSwaps = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          for (final doc in snapshot.data!.docs) {
            if (seenSwapIds.add(doc.id)) uniqueSwaps.add(doc);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: uniqueSwaps.length,
            itemBuilder: (context, i) {
              final data = uniqueSwaps[i].data();
              final swapId = uniqueSwaps[i].id;
              final otherId = data['senderId'] == user.uid
                  ? data['receiverId']
                  : data['senderId'];

              return FutureBuilder<_ChatPreviewData>(
                future: _getChatPreview(otherId, swapId, user.uid),
                builder: (context, previewSnap) {
                  if (!previewSnap.hasData) return const _ChatTileSkeleton();

                  final preview = previewSnap.data!;

                  return Card(
                    color: const Color(0xFF1E1E3F),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFFFD700),
                        backgroundImage: preview.photoUrl != null
                            ? NetworkImage(preview.photoUrl!)
                            : null,
                        child: preview.photoUrl == null
                            ? Text(
                                preview.name.isNotEmpty
                                    ? preview.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text(
                        preview.name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        preview.lastMessage,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (preview.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${preview.unreadCount}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            preview.timeAgo,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(swapId: swapId),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<_ChatPreviewData> _getChatPreview(
      String uid, String swapId, String currentUserId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String name = 'User';
      String? photoUrl;

      if (userDoc.exists) {
        final data = userDoc.data()!;
        name = (data['displayName']?.toString().trim() ?? 'User');
        photoUrl = data['photoURL']?.toString();
        if (name.isEmpty) name = 'User';
      } else {
        final email = '$uid@example.com';
        name = email.split('@').first;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'displayName': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final messagesSnap = await FirebaseFirestore.instance
          .collection('swaps')
          .doc(swapId)
          .collection('messages')
          .orderBy('time', descending: true)
          .limit(1)
          .get();

      String lastMessage = 'No messages yet';
      Timestamp? lastTime;

      if (messagesSnap.docs.isNotEmpty) {
        final msgData = messagesSnap.docs.first.data();
        lastMessage = msgData['text'] ?? 'Media';
        lastTime = msgData['time'] as Timestamp?;
      }

      int unreadCount = 0;
      if (lastTime != null) {
        final unreadSnap = await FirebaseFirestore.instance
            .collection('swaps')
            .doc(swapId)
            .collection('messages')
            .where('sender', isNotEqualTo: currentUserId)
            .get();
        unreadCount = unreadSnap.docs.length;
      }

      String timeAgo = 'Just now';
      if (lastTime != null) {
        final diff = DateTime.now().difference(lastTime.toDate());
        if (diff.inMinutes < 1) {
          timeAgo = 'now';
        } else if (diff.inHours < 1) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inDays < 1) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inDays}d ago';
        }
      }

      return _ChatPreviewData(
        name: name,
        photoUrl: photoUrl,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        timeAgo: timeAgo,
      );
    } catch (e) {
      return _ChatPreviewData(
        name: 'User',
        lastMessage: 'Error',
        unreadCount: 0,
        timeAgo: '',
      );
    }
  }
}

class _ChatPreviewData {
  final String name;
  final String? photoUrl;
  final String lastMessage;
  final int unreadCount;
  final String timeAgo;

  _ChatPreviewData({
    required this.name,
    this.photoUrl,
    required this.lastMessage,
    required this.unreadCount,
    required this.timeAgo,
  });
}

class _ChatTileSkeleton extends StatelessWidget {
  const _ChatTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E3F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: const ListTile(
        leading: CircleAvatar(backgroundColor: Color(0xFFFFD700)),
        title: LinearProgressIndicator(color: Colors.grey),
        subtitle: LinearProgressIndicator(color: Colors.grey),
      ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  final String swapId;
  const ChatRoomScreen({required this.swapId, super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late final User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('swaps')
        .doc(widget.swapId)
        .collection('messages')
        .add({
      'text': text,
      'sender': _currentUser.uid,
      'time': FieldValue.serverTimestamp(),
    });

    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('swaps')
                  .doc(widget.swapId)
                  .collection('messages')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hi!'));
                }

                final messages = snapshot.data!.docs;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final data = messages[i].data();
                    final isMe = data['sender'] == _currentUser.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color:
                              isMe ? const Color(0xFFFFD700) : Colors.grey[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(
                              color: isMe ? Colors.black87 : Colors.white,
                              fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFFFD700),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
