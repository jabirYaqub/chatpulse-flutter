import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/auth_service.dart';
import 'package:chat_app_flutter/services/storage_service.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';

// AuthController manages all user authentication, registration, and profile
// operations using Firebase Auth and Firestore. It uses GetX for state management,
// making the user's authentication state globally accessible.
class AuthController extends GetxController {
  // Service dependencies are injected for cleaner code and testability.
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  // Reactive state variables. These are observable and will automatically
  // update the UI when their values change.
  final Rx<User?> _user = Rx<User?>(null); // Holds the current Firebase user.
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null); // Holds the custom UserModel from Firestore.
  final RxBool _isLoading = false.obs; // Tracks the loading state for UI feedback.
  final RxString _error = ''.obs; // Stores any error messages.
  final RxBool _isInitialized = false.obs; // Tracks if the initial auth state has been checked.

  // Public getters to access the reactive state without exposing the Rx objects directly.
  User? get user => _user.value;
  UserModel? get userModel => _userModel.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isAuthenticated => _user.value != null; // A convenient check for authentication status.
  bool get isInitialized => _isInitialized.value;

  // Public getter for the reactive user model (useful for other controllers to listen to changes).
  Rx<UserModel?> get userModelRx => _userModel;

  /// Called automatically by GetX when the controller is first created.
  /// Used to set up stream listeners.
  @override
  void onInit() {
    super.onInit();
    // Binds the _user stream to the auth state changes from Firebase.
    // This allows the controller to react automatically to sign-in/sign-out events.
    _user.bindStream(_authService.authStateChanges);
    // 'ever' listens for changes in the _user stream and calls _handleAuthStateChange.
    ever(_user, _handleAuthStateChange);
  }

  /// Handles changes in the Firebase authentication state.
  /// This method is crucial for managing app flow based on whether a user is logged in.
  void _handleAuthStateChange(User? user) {
    if (user != null) {
      // If a user is logged in, load their corresponding data from Firestore.
      _loadUserModel(user.uid);
    }

    // Navigate the user to the appropriate screen based on their authentication status.
    // `Get.offAllNamed` is used to remove all previous routes from the stack.
    if (user == null) {
      // User is logged out.
      _userModel.value = null; // Clear the local user model.
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
    } else {
      // User is logged in.
      if (Get.currentRoute != AppRoutes.main) {
        Get.offAllNamed(AppRoutes.main);
      }
    }

    // Mark initialization as complete after the first auth state check.
    if (!_isInitialized.value) {
      _isInitialized.value = true;
    }
  }

  /// Fetches the user's custom data (UserModel) from Firestore.
  Future<void> _loadUserModel(String userId) async {
    try {
      final userModel = await _firestoreService.getUser(userId);
      if (userModel != null) {
        _userModel.value = userModel;
      }
    } catch (e) {
      // Log the error without disrupting the app flow.
      print('Failed to load user model: $e');
    }
  }

  /// This method is called from the splash screen to quickly check the initial
  /// authentication state and navigate accordingly.
  void checkInitialAuthState() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _user.value = currentUser;
      // Navigate to the main app if a user is already signed in.
      Get.offAllNamed(AppRoutes.main);
    } else {
      // Navigate to the login screen if no user is signed in.
      Get.offAllNamed(AppRoutes.login);
    }
    _isInitialized.value = true;
  }

  /// Handles user sign-in with email and password.
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      UserModel? userModel = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      if (userModel != null) {
        _userModel.value = userModel;
        // Navigate to the main app after successful sign-in.
        Get.offAllNamed(AppRoutes.main);
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', e.toString());
      print(e);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Handles new user registration with email, password, display name, and optional profile picture.
  Future<void> registerWithEmailAndPassword(
      String email,
      String password,
      String displayName, {
        File? profilePicture,
      }) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      // Upload profile picture to Firebase Storage if provided.
      String photoURL = '';
      if (profilePicture != null) {
        photoURL = await _storageService.uploadImage(profilePicture);
      }

      // Register the user with the authentication service.
      UserModel? userModel = await _authService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
        photoURL: photoURL,
      );
      if (userModel != null) {
        _userModel.value = userModel;
        // Navigate to the main app after successful registration.
        Get.offAllNamed(AppRoutes.main);
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  /// Updates the user's profile picture by uploading a new image and updating Firestore.
  Future<void> updateProfilePicture(File imageFile) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final imageUrl = await _storageService.uploadImage(imageFile);

      if (_userModel.value != null) {
        // Create a new UserModel with the updated photo URL.
        final updatedUser = _userModel.value!.copyWith(photoURL: imageUrl);
        // Save the updated user data to Firestore.
        await _firestoreService.updateUser(updatedUser);
        // Update the local reactive user model.
        _userModel.value = updatedUser;

        Get.snackbar('Success', 'Profile picture updated successfully');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to update profile picture: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// A public method to update the user model from other controllers,
  /// ensuring the state is consistent across the app.
  void updateUserModel(UserModel updatedUser) {
    _userModel.value = updatedUser;
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      _isLoading.value = true;
      await _authService.signOut();
      _userModel.value = null; // Clear local state.
      // Navigate back to the login screen.
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  /// Deletes the user's account, including data in Firestore and Firebase Auth.
  /// Requires re-authentication for security.
  Future<void> deleteAccount() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      print('🗑️ AuthController: Starting account deletion process');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Step 1: Prompt for password to re-authenticate the user for security.
      print('🔐 AuthController: Requesting password for re-authentication');
      final password = await _showPasswordDialog();
      if (password == null || password.isEmpty) {
        print('❌ AuthController: User cancelled password input');
        _isLoading.value = false;
        return; // User cancelled the dialog.
      }

      // Step 2: Re-authenticate the user with the provided password.
      print('🔑 AuthController: Re-authenticating user');
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      print('✅ AuthController: Re-authentication successful');

      // Step 3: Delete user data from Firestore first to avoid orphaned data.
      print('🗃️ AuthController: Deleting user data from Firestore');
      await _firestoreService.deleteUser(user.uid);

      // Step 4: Delete the Firebase Auth account.
      print('🔥 AuthController: Deleting Firebase Auth account');
      await user.delete();

      // Step 5: Clear local state to reflect the account deletion.
      _userModel.value = null;

      // Step 6: Show a success message and navigate to the login screen.
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
          errorMessage = 'Failed to delete account: ${e.message}';
      }
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
      // Catch and handle any other general errors.
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
      _isLoading.value = false;
      print('🏁 AuthController: Account deletion process completed');
    }
  }

  /// Displays a modal dialog to securely collect the user's password for re-authentication.
  Future<String?> _showPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();
    final RxBool obscurePassword = true.obs;

    return await Get.dialog<String>(
      AlertDialog(
        title: const Text(
          'Confirm Account Deletion',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To delete your account, please enter your current password:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Obx(() => TextField(
              controller: passwordController,
              obscureText: obscurePassword.value,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline),
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
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Get.back(result: value.trim());
                }
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text.trim();
              if (password.isNotEmpty) {
                Get.back(result: password);
              } else {
                Get.snackbar(
                  'Error',
                  'Please enter your password',
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.red,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
      // Prevents the dialog from being dismissed by tapping outside.
      barrierDismissible: false,
    );
  }

  /// Clears the current error message.
  void clearError() {
    _error.value = '';
  }
}