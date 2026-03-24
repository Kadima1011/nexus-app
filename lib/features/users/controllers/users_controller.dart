import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/models/user_model.dart';

class UsersController extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;

  // Stream all users except current user
  Stream<List<UserModel>> get usersStream => _firestore
      .collection('users')
      .snapshots()
      .map((snap) => snap.docs
      .map((d) => UserModel.fromDoc(d))
      .where((u) => u.uid != currentUid)
      .toList());

  // Get or create a conversation between two users
  Future<String> getOrCreateConversation(String otherUid) async {
    final myUid = currentUid;

    // Check if conversation already exists
    final existing = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: myUid)
        .get();

    for (final doc in existing.docs) {
      final participants =
      List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUid)) {
        return doc.id;
      }
    }

    // Get both user details
    final myDoc =
    await _firestore.collection('users').doc(myUid).get();
    final otherDoc =
    await _firestore.collection('users').doc(otherUid).get();

    final myName = myDoc.data()?['name'] ?? '';
    final myPhoto = myDoc.data()?['photoUrl'] ?? '';
    final otherName = otherDoc.data()?['name'] ?? '';
    final otherPhoto = otherDoc.data()?['photoUrl'] ?? '';

    // Create new conversation
    final ref = await _firestore.collection('conversations').add({
      'participants': [myUid, otherUid],
      'participantNames': {myUid: myName, otherUid: otherName},
      'participantPhotos': {myUid: myPhoto, otherUid: otherPhoto},
      'lastMessage': '',
      'lastMessageSenderId': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': {myUid: 0, otherUid: 0},
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }
}