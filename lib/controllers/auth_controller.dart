import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/auth_service.dart';
import 'package:chat_app_flutter/services/storage_service.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';

/// AuthController manages all user authentication, registration, and profile
/// operations using Firebase Auth and Firestore. It uses GetX for state management,
/// making the user's authentication state globally accessible throughout the app.
///
/// This controller handles:
/// - User sign-in/sign-up with email and password
/// - Profile picture updates and user data management
/// - Account deletion with security re-authentication
/// - Automatic navigation based on authentication state
/// - Loading states and error handling for all auth operations
class AuthController extends GetxController {

  // ==================== SERVICE DEPENDENCIES ====================

  /// Service dependencies are injected for cleaner code and testability.
  /// These services handle specific aspects of authentication and data management.
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  // ==================== REACTIVE STATE VARIABLES ====================

  /// Reactive state variables. These are observable and will automatically
  /// update the UI when their values change using GetX's reactive system.

  /// Holds the current Firebase user object containing basic auth info
  final Rx<User?> _user = Rx<User?>(null);

  /// Holds the custom UserModel from Firestore with additional user data
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);

  /// Tracks the loading state for UI feedback (shows progress indicators)
  final RxBool _isLoading = false.obs;

  /// Stores any error messages to display to the user
  final RxString _error = ''.obs;

  /// Tracks if the initial auth state has been checked (prevents navigation loops)
  final RxBool _isInitialized = false.obs;

  // ==================== PUBLIC GETTERS ====================

  /// Public getters to access the reactive state without exposing the Rx objects directly.
  /// This provides a clean API for other controllers and UI components.

  /// Returns the current Firebase user or null if not authenticated
  User? get user => _user.value;

  /// Returns the custom user model with extended profile information
  UserModel? get userModel => _userModel.value;

  /// Returns true if any authentication operation is in progress
  bool get isLoading => _isLoading.value;

  /// Returns the current error message or empty string if no error
  String get error => _error.value;

  /// A convenient check for authentication status - true if user is logged in
  bool get isAuthenticated => _user.value != null;

  /// Returns true once the initial authentication state has been determined
  bool get isInitialized => _isInitialized.value;

  /// Public getter for the reactive user model (useful for other controllers to listen to changes).
  /// This allows other parts of the app to react to user model changes automatically.
  Rx<UserModel?> get userModelRx => _userModel;

  // ==================== LIFECYCLE METHODS ====================

  /// Called automatically by GetX when the controller is first created.
  /// Used to set up stream listeners and initialize reactive bindings.
  @override
  void onInit() {
    super.onInit();
    // Binds the _user stream to the auth state changes from Firebase.
    // This allows the controller to react automatically to sign-in/sign-out events.
    _user.bindStream(_authService.authStateChanges);
    // 'ever' listens for changes in the _user stream and calls _handleAuthStateChange.
    // This creates a reactive chain: Firebase auth changes → _user updates → navigation occurs
    ever(_user, _handleAuthStateChange);
  }

  // ==================== AUTHENTICATION STATE MANAGEMENT ====================

  /// Handles changes in the Firebase authentication state.
  /// This method is crucial for managing app flow based on whether a user is logged in.
  /// It automatically navigates users to appropriate screens and loads user data.
  void _handleAuthStateChange(User? user) {
    if (user != null) {
      // If a user is logged in, load their corresponding data from Firestore.
      // This ensures we have complete user profile information beyond just auth data.
      _loadUserModel(user.uid);
    }

    // Navigate the user to the appropriate screen based on their authentication status.
    // `Get.offAllNamed` is used to remove all previous routes from the stack.
    if (user == null) {
      // User is logged out - clear data and go to login
      _userModel.value = null; // Clear the local user model to prevent stale data.
      // Only navigate if we're not already on the login screen (prevents navigation loops)
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
    } else {
      // User is logged in - go to main app
      // Only navigate if we're not already on the main screen (prevents navigation loops)
      if (Get.currentRoute != AppRoutes.main) {
        Get.offAllNamed(AppRoutes.main);
      }
    }

    // Mark initialization as complete after the first auth state check.
    // This prevents multiple navigation attempts during app startup.
    if (!_isInitialized.value) {
      _isInitialized.value = true;
    }
  }

  /// Fetches the user's custom data (UserModel) from Firestore.
  /// This supplements Firebase Auth data with additional profile information
  /// stored in our Firestore database (display name, profile picture, etc.).
  Future<void> _loadUserModel(String userId) async {
    try {
      // Attempt to fetch user data from Firestore using their unique ID
      final userModel = await _firestoreService.getUser(userId);
      if (userModel != null) {
        // Update the reactive user model, which will notify all listeners
        _userModel.value = userModel;
      }
    } catch (e) {
      // Log the error without disrupting the app flow.
      // User can still use the app with basic Firebase Auth data even if Firestore fails.
      print('Failed to load user model: $e');
    }
  }

  /// This method is called from the splash screen to quickly check the initial
  /// authentication state and navigate accordingly. It bypasses the reactive stream
  /// for faster initial loading.
  void checkInitialAuthState() {
    // Get the current user directly from Firebase Auth (synchronous call)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // User is already signed in - update our state and navigate to main app
      _user.value = currentUser;
      // Navigate to the main app if a user is already signed in.
      Get.offAllNamed(AppRoutes.main);
    } else {
      // No user signed in - navigate to login screen
      // Navigate to the login screen if no user is signed in.
      Get.offAllNamed(AppRoutes.login);
    }
    // Mark initialization as complete
    _isInitialized.value = true;
  }

  // ==================== AUTHENTICATION OPERATIONS ====================

  /// Handles user sign-in with email and password.
  /// Updates loading state, handles errors, and navigates on success.
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Set loading state to show progress indicators in UI
      _isLoading.value = true;
      // Clear any previous error messages
      _error.value = '';

      // Attempt to sign in using the authentication service
      UserModel? userModel = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      if (userModel != null) {
        // Update local user model with the returned data
        _userModel.value = userModel;
        // Navigate to the main app after successful sign-in.
        Get.offAllNamed(AppRoutes.main);
      }
    } catch (e) {
      // Store error message for UI display
      _error.value = e.toString();
      // Show immediate error feedback to user
      Get.snackbar('Error', e.toString());
      // Log error for debugging purposes
      print(e);
    } finally {
      // Always reset loading state, regardless of success or failure
      _isLoading.value = false;
    }
  }

  /// Handles new user registration with email, password, display name, and optional profile picture.
  /// Includes profile picture upload to Firebase Storage if provided.
  Future<void> registerWithEmailAndPassword(
      String email,
      String password,
      String displayName, {
        File? profilePicture, // Optional profile picture file
      }) async {
    try {
      // Set loading state for UI feedback
      _isLoading.value = true;
      _error.value = '';

      // Upload profile picture to Cloudinary Storage if provided.
      String photoURL = '';
      if (profilePicture != null) {
        // Upload image and get the download URL
        photoURL = await _storageService.uploadImage(profilePicture);
      }

      // Register the user with the authentication service, including profile data
      UserModel? userModel = await _authService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
        photoURL: photoURL, // Pass the uploaded image URL
      );
      if (userModel != null) {
        // Update local state with new user data
        _userModel.value = userModel;
        // Navigate to the main app after successful registration.
        Get.offAllNamed(AppRoutes.main);
      }
    } catch (e) {
      // Handle and display any registration errors
      _error.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      // Reset loading state
      _isLoading.value = false;
    }
  }

  // ==================== PROFILE MANAGEMENT ====================

  /// Updates the user's profile picture by uploading a new image and updating Firestore.
  /// This involves uploading to Storage, updating Firestore, and refreshing local state.
  Future<void> updateProfilePicture(File imageFile) async {
    try {
      // Set loading state for UI feedback during upload
      _isLoading.value = true;
      _error.value = '';

      // Upload the new image to Cloudinary Storage and get download URL
      final imageUrl = await _storageService.uploadImage(imageFile);

      if (_userModel.value != null) {
        // Create a new UserModel with the updated photo URL.
        // Using copyWith ensures all other user data remains unchanged.
        final updatedUser = _userModel.value!.copyWith(photoURL: imageUrl);

        // Save the updated user data to Firestore for persistence
        await _firestoreService.updateUser(updatedUser);

        // Update the local reactive user model to reflect changes immediately
        _userModel.value = updatedUser;

        // Show success feedback to user
        Get.snackbar('Success', 'Profile picture updated successfully');
      }
    } catch (e) {
      // Handle upload or update errors
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to update profile picture: ${e.toString()}');
    } finally {
      // Reset loading state
      _isLoading.value = false;
    }
  }

  /// A public method to update the user model from other controllers,
  /// ensuring the state is consistent across the app. This allows other
  /// parts of the app to update user data and have it reflected everywhere.
  void updateUserModel(UserModel updatedUser) {
    _userModel.value = updatedUser;
  }

  /// Signs out the current user and navigates back to login screen.
  /// Clears all local state to ensure no sensitive data remains.
  Future<void> signOut() async {
    try {
      // Set loading state
      _isLoading.value = true;
      // Call Firebase sign out through our auth service
      await _authService.signOut();
      // Clear local state to remove any cached user data
      _userModel.value = null;
      // Navigate back to the login screen.
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      // Handle sign-out errors (rare but possible)
      _error.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      // Reset loading state
      _isLoading.value = false;
    }
  }

  // ==================== ACCOUNT DELETION ====================

  /// Deletes the user's account, including data in Firestore and Firebase Auth.
  /// Requires re-authentication for security. This is a multi-step process that
  /// ensures data consistency and security compliance.
  Future<void> deleteAccount() async {
    try {
      // Set loading state to prevent multiple deletion attempts
      _isLoading.value = true;
      _error.value = '';

      // Debug logging to track the deletion process
      print('🗑️ AuthController: Starting account deletion process');

      // Ensure we have a current user to delete
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Step 1: Prompt for password to re-authenticate the user for security.
      // This is required by Firebase for sensitive operations like account deletion.
      print('🔐 AuthController: Requesting password for re-authentication');
      final password = await _showPasswordDialog();
      if (password == null || password.isEmpty) {
        // User cancelled the operation
        print('❌ AuthController: User cancelled password input');
        _isLoading.value = false;
        return; // User cancelled the dialog.
      }

      // Step 2: Re-authenticate the user with the provided password.
      // This ensures the user currently knows their password and has active access.
      print('🔑 AuthController: Re-authenticating user');
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      print('✅ AuthController: Re-authentication successful');

      // Step 3: Delete user data from Firestore first to avoid orphaned data.
      // It's important to delete Firestore data before Auth to prevent data inconsistencies.
      print('🗃️ AuthController: Deleting user data from Firestore');
      await _firestoreService.deleteUser(user.uid);

      // Step 4: Delete the Firebase Auth account.
      // This removes the user's authentication credentials completely.
      print('🔥 AuthController: Deleting Firebase Auth account');
      await user.delete();

      // Step 5: Clear local state to reflect the account deletion.
      // Remove any cached user data from the app.
      _userModel.value = null;

      // Step 6: Show a success message and navigate to the login screen.
      // Provide user feedback with a styled success message.
      Get.snackbar(
        'Success',
        'Account deleted successfully',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
      print('🚀 AuthController: Navigating to login screen');
      Get.offAllNamed(AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors gracefully.
      // Different error codes require different user messaging.
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please sign out and sign in again, then try deleting your account.';
          break;
        case 'user-not-found':
          errorMessage = 'User account not found.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection and try again.';
          break;
        default:
        // Fallback for any other Firebase Auth errors
          errorMessage = 'Failed to delete account: ${e.message}';
      }
      // Log error for debugging
      print('❌ AuthController: Firebase Auth error: ${e.code} - $errorMessage');
      _error.value = errorMessage;
      // Show an error snackbar with detailed information.
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } catch (e) {
      // Catch and handle any other general errors not covered by FirebaseAuthException.
      print('❌ AuthController: General error: $e');
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to delete account: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      // Always reset loading state and log completion
      _isLoading.value = false;
      print('🏁 AuthController: Account deletion process completed');
    }
  }

  /// Displays a modal dialog to securely collect the user's password for re-authentication.
  /// This dialog ensures the user confirms their identity before sensitive operations.
  /// Returns the entered password or null if cancelled.
  Future<String?> _showPasswordDialog() async {
    // Controller for the password input field
    final TextEditingController passwordController = TextEditingController();
    // Reactive boolean to toggle password visibility
    final RxBool obscurePassword = true.obs;

    // Show dialog and wait for user interaction
    return await Get.dialog<String>(
      AlertDialog(
        // Dialog title explaining the purpose
        title: const Text(
          'Confirm Account Deletion',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Only use necessary space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanation text for why password is needed
            const Text(
              'To delete your account, please enter your current password:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16), // Spacing
            // Password input field with reactive visibility toggle
            Obx(() => TextField(
              controller: passwordController,
              obscureText: obscurePassword.value, // Hide/show password
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline),
                // Toggle button for password visibility
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => obscurePassword.toggle(),
                ),
                border: const OutlineInputBorder(),
              ),
              // Allow user to submit by pressing Enter
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Get.back(result: value.trim());
                }
              },
            )),
          ],
        ),
        actions: [
          // Cancel button - returns null
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancel'),
          ),
          // Delete button - validates input and returns password
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text.trim();
              if (password.isNotEmpty) {
                // Return the password to continue deletion process
                Get.back(result: password);
              } else {
                // Show error if password field is empty
                Get.snackbar(
                  'Error',
                  'Please enter your password',
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.red,
                );
              }
            },
            // Style the delete button with red color to indicate danger
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
      // Prevents the dialog from being dismissed by tapping outside.
      // Forces user to explicitly choose Cancel or Delete.
      barrierDismissible: false,
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Clears the current error message.
  /// Useful for resetting error state before new operations or when user dismisses errors.
  void clearError() {
    _error.value = '';
  }
}
