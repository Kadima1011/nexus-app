import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  bool isLoading = false;
  String? errorMessage;

  User? get currentUser => _auth.currentUser;

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  void _setError(String? msg) {
    errorMessage = msg;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'photoUrl': '',
        'bio': '',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }).catchError((e) => debugPrint('Firestore save failed: $e'));

      cred.user!.updateDisplayName(name.trim())
          .catchError((e) => debugPrint('Display name failed: $e'));

      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      return false;
    } catch (e) {
      _setError('Something went wrong. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Set online status
      final uid = _auth.currentUser!.uid;
      _firestore.collection('users').doc(uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }).catchError((e) => debugPrint('Online status failed: $e'));

      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      return false;
    } catch (e) {
      _setError('Something went wrong. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final doc = await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists) {
        _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': cred.user!.displayName ?? '',
          'email': cred.user!.email ?? '',
          'photoUrl': cred.user!.photoURL ?? '',
          'bio': '',
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }).catchError((e) => debugPrint('Firestore save failed: $e'));
      } else {
        _firestore.collection('users').doc(cred.user!.uid).update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        }).catchError((e) => debugPrint('Online status failed: $e'));
      }

      return true;
    } catch (e) {
      _setError('Google sign-in failed. Try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }).catchError((e) => debugPrint('Sign out status failed: $e'));
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
    notifyListeners();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}