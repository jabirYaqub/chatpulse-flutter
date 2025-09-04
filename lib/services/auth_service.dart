import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';

/// Service class that handles all authentication operations for the application.
/// This class provides a centralized way to manage user authentication using Firebase Auth
/// and coordinates with Firestore to maintain user data and online status.
class AuthService {
  // =============================================================================
  // PRIVATE INSTANCES
  // =============================================================================

  /// Firebase Authentication instance for handling auth operations
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Firestore service instance for managing user data in the database
  final FirestoreService _firestoreService = FirestoreService();

  // =============================================================================
  // PUBLIC GETTERS
  // =============================================================================

  /// Returns the currently authenticated Firebase user, null if not authenticated
  User? get currentUser => _auth.currentUser;

  /// Returns the UID of the currently authenticated user, null if not authenticated
  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream that emits authentication state changes (login/logout events)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // =============================================================================
  // AUTHENTICATION METHODS
  // =============================================================================

  /// Signs in an existing user with email and password credentials.
  ///
  /// Returns a [UserModel] object containing user data from Firestore on success.
  /// Updates the user's online status to true upon successful login.
  /// Throws an [Exception] with error details if sign-in fails.
  ///
  /// [email] - User's email address
  /// [password] - User's password
  Future<UserModel?> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      // Attempt to sign in with Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        // Update user's online status in Firestore
        await _firestoreService.updateUserOnlineStatus(user.uid, true);
        // Retrieve and return user data from Firestore
        return await _firestoreService.getUser(user.uid);
      }
      return null;
    } catch (e) {
      // Re-throw with more descriptive error message
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  /// Registers a new user with email, password, and display name.
  ///
  /// Creates a new Firebase Auth user and corresponding Firestore document.
  /// Updates the user's profile with display name and optional photo URL.
  /// Sets initial online status and timestamps.
  ///
  /// [email] - New user's email address
  /// [password] - New user's password
  /// [displayName] - User's display name
  /// [photoURL] - Optional profile photo URL (defaults to empty string)
  ///
  /// Returns a [UserModel] object for the newly created user.
  /// Throws an [Exception] with error details if registration fails.
  Future<UserModel?> registerWithEmailAndPassword(
      String email,
      String password,
      String displayName, {
        String photoURL = '',
      }) async {
    try {
      // Create new user account with Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        // Update the user's profile information
        await user.updateDisplayName(displayName);
        if (photoURL.isNotEmpty) {
          await user.updatePhotoURL(photoURL);
        }

        // Create UserModel object with initial values
        final userModel = UserModel(
          id: user.uid,
          email: email,
          displayName: displayName,
          photoURL: photoURL,
          isOnline: true, // Set as online immediately after registration
          lastSeen: DateTime.now(),
          createdAt: DateTime.now(),
        );

        // Save user data to Firestore database
        await _firestoreService.createUser(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      // Re-throw with more descriptive error message
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  // =============================================================================
  // PASSWORD MANAGEMENT
  // =============================================================================

  /// Sends a password reset email to the specified email address.
  ///
  /// Firebase will send an email with a link to reset the password.
  /// The email must be associated with an existing account.
  ///
  /// [email] - Email address to send the reset link to
  /// Throws an [Exception] with error details if the operation fails.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      // Re-throw with more descriptive error message
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // =============================================================================
  // SESSION MANAGEMENT
  // =============================================================================

  /// Signs out the currently authenticated user.
  ///
  /// Updates the user's online status to false in Firestore before signing out.
  /// This ensures other users can see when someone goes offline.
  /// Throws an [Exception] with error details if sign-out fails.
  Future<void> signOut() async {
    try {
      // Update online status to false before signing out
      if (currentUserId != null) {
        await _firestoreService.updateUserOnlineStatus(currentUserId!, false);
      }
      // Sign out from Firebase Auth
      await _auth.signOut();
    } catch (e) {
      // Re-throw with more descriptive error message
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // =============================================================================
  // ACCOUNT MANAGEMENT
  // =============================================================================

  /// Permanently deletes the current user's account and all associated data.
  ///
  /// This operation:
  /// 1. Deletes the user's data from Firestore
  /// 2. Deletes the user's Firebase Auth account
  ///
  /// WARNING: This operation is irreversible.
  /// Throws an [Exception] with error details if deletion fails.
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore first
        await _firestoreService.deleteUser(user.uid);
        // Delete the Firebase Auth user account
        await user.delete();
      }
    } catch (e) {
      // Re-throw with more descriptive error message
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
}
