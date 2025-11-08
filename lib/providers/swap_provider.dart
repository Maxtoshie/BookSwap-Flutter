import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SwapProvider with ChangeNotifier {
  List<Map<String, dynamic>> _swaps = [];

  List<Map<String, dynamic>> get swaps => _swaps;

  void listenToSwaps(String uid) {
    FirebaseFirestore.instance
        .collection('swapRequests')
        .where('toUserId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      _swaps = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      notifyListeners();
    });
  }
}
