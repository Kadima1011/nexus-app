import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../models/user_model.dart';

class ProfileController extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  bool isLoading = false;
  bool isSaving = false;
  UserModel? userProfile;
  String? errorMessage;

  User? get currentUser => _auth.currentUser;

  Future<void> fetchProfile(String uid) async {
    isLoading = true;
    notifyListeners();
    try {
      final doc =
      await _firestore.collection('users').doc(uid).get();
      if (doc.exists) userProfile = UserModel.fromDoc(doc);
    } catch (e) {
      errorMessage = 'Failed to load profile.';
      debugPrint('Profile fetch error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String bio,
    Uint8List? photoBytes,
    String? photoName,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser!.uid;
      String? photoUrl;

      if (photoBytes != null && photoName != null) {
        try {
          final ref = _storage.ref().child(
              'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}_$photoName');
          final uploadTask = await ref.putData(
            photoBytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          photoUrl = await uploadTask.ref.getDownloadURL();
        } catch (e) {
          debugPrint('Photo upload failed: $e');
          errorMessage =
          'Photo upload failed — profile saved without photo.';
        }
      }

      final updates = <String, dynamic>{
        'name': name.trim(),
        'bio': bio.trim(),
      };
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(uid).update(updates);
      await _auth.currentUser!.updateDisplayName(name.trim());
      await fetchProfile(uid);
      return true;
    } catch (e) {
      errorMessage = 'Failed to update profile.';
      debugPrint('Profile update error: $e');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}