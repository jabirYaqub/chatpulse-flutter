import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await _firestoreService.updateUserOnlineStatus(user.uid, true);
        return await _firestoreService.getUser(user.uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  Future<UserModel?> registerWithEmailAndPassword(
      String email,
      String password,
      String displayName, {
        String photoURL = '',
      }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoURL.isNotEmpty) {
          await user.updatePhotoURL(photoURL);
        }

        final userModel = UserModel(
          id: user.uid,
          email: email,
          displayName: displayName,
          photoURL: photoURL,
          isOnline: true,
          lastSeen: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await _firestoreService.createUser(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      if (currentUserId != null) {
        await _firestoreService.updateUserOnlineStatus(currentUserId!, false);
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestoreService.deleteUser(user.uid);
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
}