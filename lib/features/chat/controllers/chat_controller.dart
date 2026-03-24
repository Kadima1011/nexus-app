import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../models/message_model.dart';

class ChatController extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  bool isSending = false;
  String? errorMessage;

  String get currentUid => _auth.currentUser!.uid;

  // Real-time messages stream
  Stream<List<MessageModel>> messagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => MessageModel.fromDoc(d)).toList());
  }

  // Send text message
  Future<bool> sendMessage({
    required String conversationId,
    required String content,
    required String otherUid,
  }) async {
    if (content.trim().isEmpty) return false;
    isSending = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();

      // Add message
      final msgRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      batch.set(msgRef, {
        'senderId': currentUid,
        'content': content.trim(),
        'imageUrl': null,
        'type': 'text',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update conversation
      final convoRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      batch.update(convoRef, {
        'lastMessage': content.trim(),
        'lastMessageSenderId': currentUid,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$otherUid': FieldValue.increment(1),
      });

      await batch.commit();
      return true;
    } catch (e) {
      errorMessage = 'Failed to send message.';
      debugPrint('Send message error: $e');
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  // Send image message
  Future<bool> sendImage({
    required String conversationId,
    required String otherUid,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return false;

    isSending = true;
    notifyListeners();

    try {
      final bytes = await picked.readAsBytes();
      final ref = _storage.ref().child(
          'chat_images/$conversationId/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = await ref.putData(bytes);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      final batch = _firestore.batch();

      final msgRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      batch.set(msgRef, {
        'senderId': currentUid,
        'content': '📷 Image',
        'imageUrl': imageUrl,
        'type': 'image',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final convoRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      batch.update(convoRef, {
        'lastMessage': '📷 Image',
        'lastMessageSenderId': currentUid,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$otherUid': FieldValue.increment(1),
      });

      await batch.commit();
      return true;
    } catch (e) {
      errorMessage = 'Failed to send image.';
      debugPrint('Send image error: $e');
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    try {
      // Reset unread count
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({'unreadCount.$currentUid': 0});

      // Mark unread messages as read
      final unread = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUid)
          .get();

      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  // Stream other user's online status
  Stream<bool> onlineStream(String otherUid) {
    return _firestore
        .collection('users')
        .doc(otherUid)
        .snapshots()
        .map((doc) => doc.data()?['isOnline'] ?? false);
  }
}