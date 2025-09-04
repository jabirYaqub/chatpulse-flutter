import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/services/storage_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';

/// ProfileController manages all user profile-related functionality including
/// profile viewing, editing, profile picture management, and account operations.
/// This controller handles complex data synchronization between Firebase Auth,
/// Firestore, and local state with robust error handling and fallback mechanisms.
///
/// This controller is responsible for:
/// - Loading user profile data with multiple fallback strategies
/// - Profile editing with real-time validation and updates
/// - Profile picture upload/update/removal with image optimization
/// - Account deletion with comprehensive warnings and re-authentication
/// - State synchronization between AuthController and Firestore
/// - Error handling and recovery for network and authentication issues
/// - Fallback user creation when Firestore data is missing
/// - Memory management and resource cleanup
class ProfileController extends GetxController {

  // ==================== DEPENDENCIES ====================

  /// Service dependencies for data access and functionality
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final AuthController _authController = Get.find<AuthController>();
  final ImagePicker _imagePicker = ImagePicker();

  // ==================== FORM CONTROLLERS ====================

  /// Text controllers for profile form fields
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // ==================== REACTIVE STATE VARIABLES ====================

  /// Reactive state management using GetX observables
  /// These automatically trigger UI updates when values change

  /// General loading state for profile operations
  final RxBool _isLoading = false.obs;

  /// Edit mode toggle for profile form
  final RxBool _isEditing = false.obs;

  /// Error message storage for user feedback
  final RxString _error = ''.obs;

  /// Current user profile data with real-time updates
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);

  /// Specific loading state for profile picture uploads
  final RxBool _isUploadingImage = false.obs;

  // ==================== PUBLIC GETTERS ====================

  /// Public getters providing controlled access to reactive state
  bool get isLoading => _isLoading.value;
  bool get isEditing => _isEditing.value;
  String get error => _error.value;
  UserModel? get currentUser => _currentUser.value;
  bool get isUploadingImage => _isUploadingImage.value;

  // ==================== LIFECYCLE METHODS ====================

  /// Controller initialization with comprehensive data loading
  @override
  void onInit() {
    super.onInit();
    print('🔄 ProfileController: onInit called');
    _loadUserData();
  }

  /// Controller cleanup to prevent memory leaks
  @override
  void onClose() {
    // Dispose text controllers to free memory
    displayNameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  // ==================== DATA LOADING WITH FALLBACK STRATEGIES ====================

  /// Loads user data with multiple fallback strategies for robustness
  /// This method attempts several approaches to ensure user data is available
  void _loadUserData() {
    final currentUserId = _authController.user?.uid;
    print('👤 ProfileController: Loading user data for ID: $currentUserId');

    if (currentUserId != null) {
      // First, try to get user from AuthController (fastest method)
      final authUser = _authController.userModel;
      if (authUser != null) {
        print('✅ ProfileController: Found user in AuthController: ${authUser.displayName}');
        _currentUser.value = authUser;
        displayNameController.text = authUser.displayName;
        emailController.text = authUser.email;
        return;
      }

      // If not found in AuthController, try Firestore stream (real-time updates)
      print('🔍 ProfileController: Trying Firestore stream...');
      try {
        // Bind to real-time Firestore stream for automatic updates
        _currentUser.bindStream(_firestoreService.getUserStream(currentUserId));

        // React to stream changes and update form fields
        ever(_currentUser, (UserModel? user) {
          if (user != null) {
            print('✅ ProfileController: User data loaded from Firestore: ${user.displayName}');
            displayNameController.text = user.displayName;
            emailController.text = user.email;
          } else {
            print('❌ ProfileController: No user data found in Firestore');
            // Fall back to creating user from Firebase Auth data
            _tryCreateUserFromFirebaseAuth();
          }
        });

        // Add timeout to detect if stream is not working and trigger fallback
        Future.delayed(const Duration(seconds: 3), () {
          if (_currentUser.value == null) {
            print('⏰ ProfileController: Timeout - trying alternative method');
            _tryCreateUserFromFirebaseAuth();
          }
        });

      } catch (e) {
        print('❌ ProfileController: Error binding to Firestore stream: $e');
        // Fall back to creating user from Firebase Auth if stream fails
        _tryCreateUserFromFirebaseAuth();
      }
    } else {
      print('❌ ProfileController: No current user ID found');
      _error.value = 'No user logged in';
    }
  }

  /// Fallback method to create user from Firebase Auth data when Firestore fails
  /// This ensures the app can function even if Firestore user document is missing
  void _tryCreateUserFromFirebaseAuth() {
    print('🔧 ProfileController: Trying to create user from Firebase Auth data');

    final firebaseUser = _authController.user;
    if (firebaseUser != null) {
      // Create a fallback UserModel from Firebase Auth user data
      final fallbackUser = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'User',
        photoURL: firebaseUser.photoURL ?? '',
        isOnline: true,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
      );

      print('🆘 ProfileController: Created fallback user: ${fallbackUser.displayName}');
      // Update local state with fallback user
      _currentUser.value = fallbackUser;
      displayNameController.text = fallbackUser.displayName;
      emailController.text = fallbackUser.email;

      // Try to save this user to Firestore for future use
      _saveUserToFirestore(fallbackUser);
    } else {
      print('❌ ProfileController: No Firebase user found either');
      _error.value = 'Unable to load user data';
    }
  }

  /// Save user to Firestore with fallback to creation if update fails
  /// This handles cases where user document doesn't exist yet
  Future<void> _saveUserToFirestore(UserModel user) async {
    try {
      print('💾 ProfileController: Saving user to Firestore');
      // Try updating existing user document first
      await _firestoreService.updateUser(user);
      print('✅ ProfileController: User saved to Firestore successfully');
    } catch (e) {
      print('❌ ProfileController: Failed to save user to Firestore: $e');
      // Try creating user instead of updating if document doesn't exist
      try {
        await _firestoreService.createUser(user);
        print('✅ ProfileController: User created in Firestore successfully');
      } catch (createError) {
        print('❌ ProfileController: Failed to create user in Firestore: $createError');
      }
    }
  }

  // ==================== RECOVERY AND DEBUG METHODS ====================

  /// Force reset method to fix stuck loading states and reinitialize
  /// This is a recovery mechanism for when the controller gets into a bad state
  void forceReset() {
    print('🔄 ProfileController: Force reset called');
    // Reset all loading and error states
    _isLoading.value = false;
    _isUploadingImage.value = false;
    _error.value = '';
    _currentUser.value = null;
    // Reinitialize data loading
    _loadUserData();
  }

  // ==================== PROFILE EDITING ====================

  /// Toggle between view and edit modes for the profile
  /// Resets form fields to original values when canceling edit
  void toggleEditing() {
    _isEditing.value = !_isEditing.value;

    if (!_isEditing.value) {
      // Reset fields if canceling edit to original values
      final user = _currentUser.value;
      if (user != null) {
        displayNameController.text = user.displayName;
        emailController.text = user.email;
      }
    }
  }

  /// Update user profile with form data and sync across all systems
  Future<void> updateProfile() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final user = _currentUser.value;
      if (user == null) return;

      // Create updated user model with new display name
      final updatedUser = user.copyWith(
        displayName: displayNameController.text.trim(),
      );

      try {
        // Try to update existing user document
        await _firestoreService.updateUser(updatedUser);
      } catch (e) {
        // If update fails, try to create the user document
        await _firestoreService.createUser(updatedUser);
      }

      // Update auth controller's user model for consistency across app
      _authController.updateUserModel(updatedUser);
      // Update local state
      _currentUser.value = updatedUser;

      // Exit edit mode and show success feedback
      _isEditing.value = false;
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      // Handle update errors with user feedback
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}');
    } finally {
      // Always reset loading state
      _isLoading.value = false;
    }
  }

  // ==================== PROFILE PICTURE MANAGEMENT ====================

  /// Update profile picture with image source selection and optimization
  /// Handles camera/gallery selection, image optimization, and upload
  Future<void> updateProfilePicture() async {
    try {
      // Show dialog to choose image source (camera or gallery)
      final result = await Get.dialog<ImageSource>(
        AlertDialog(
          title: const Text('Update Profile Picture'),
          content: const Text('Choose how you want to select your new profile picture'),
          actions: [
            TextButton.icon(
              onPressed: () => Get.back(result: ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            TextButton.icon(
              onPressed: () => Get.back(result: ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
          ],
        ),
      );

      if (result != null) {
        _isUploadingImage.value = true;

        // Pick image with optimization settings for performance and storage
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: result,
          maxWidth: 512, // Optimize image size
          maxHeight: 512,
          imageQuality: 80, // Balance quality and file size
        );

        if (pickedFile != null) {
          print('📷 ProfileController: Uploading image...');
          // Convert to File and upload to Firebase Storage
          final imageFile = File(pickedFile.path);
          final imageUrl = await _storageService.uploadImage(imageFile);
          print('✅ ProfileController: Image uploaded: $imageUrl');

          final user = _currentUser.value;
          if (user != null) {
            // Create updated user with new profile picture URL
            final updatedUser = user.copyWith(photoURL: imageUrl);

            try {
              // Try to update user in Firestore
              print('💾 ProfileController: Updating user in Firestore...');
              await _firestoreService.updateUser(updatedUser);
              print('✅ ProfileController: User updated in Firestore');
            } catch (firestoreError) {
              // If Firestore update fails, create the user document
              print('⚠️ ProfileController: Firestore update failed, creating user: $firestoreError');
              try {
                await _firestoreService.createUser(updatedUser);
                print('✅ ProfileController: User created in Firestore');
              } catch (createError) {
                print('❌ ProfileController: Failed to create user: $createError');
                // Continue anyway, at least update local state
              }
            }

            // Update local state regardless of Firestore success
            _currentUser.value = updatedUser;

            // Update auth controller's user model for app-wide consistency
            _authController.updateUserModel(updatedUser);

            // Show success feedback with styled snackbar
            Get.snackbar(
              'Success',
              'Profile picture updated successfully',
              backgroundColor: Colors.green.withOpacity(0.1),
              colorText: Colors.green,
              icon: const Icon(Icons.check_circle, color: Colors.green),
            );
          }
        }
      }
    } catch (e) {
      print('❌ ProfileController: Error updating profile picture: $e');
      _error.value = e.toString();
      // Show error feedback with styled snackbar
      Get.snackbar(
        'Error',
        'Failed to update profile picture. Please try again.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      // Always reset upload state
      _isUploadingImage.value = false;
    }
  }

  /// Remove profile picture with confirmation dialog
  Future<void> removeProfilePicture() async {
    try {
      // Show confirmation dialog to prevent accidental removal
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Remove Profile Picture'),
          content: const Text('Are you sure you want to remove your profile picture?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (result == true) {
        _isLoading.value = true;

        final user = _currentUser.value;
        if (user != null) {
          // Create updated user with empty photo URL
          final updatedUser = user.copyWith(photoURL: '');

          try {
            // Try to update in Firestore
            await _firestoreService.updateUser(updatedUser);
          } catch (e) {
            // If update fails, try to create the user
            await _firestoreService.createUser(updatedUser);
          }

          // Update local state
          _currentUser.value = updatedUser;

          // Update auth controller's user model
          _authController.updateUserModel(updatedUser);

          Get.snackbar('Success', 'Profile picture removed successfully');
        }
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to remove profile picture: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  // ==================== ACCOUNT OPERATIONS ====================

  /// Sign out user through AuthController
  Future<void> signOut() async {
    try {
      // Delegate to AuthController for consistent sign-out handling
      await _authController.signOut();
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: ${e.toString()}');
    }
  }

  /// Enhanced account deletion with comprehensive warnings and confirmation
  /// This method provides clear information about what will be deleted
  Future<void> deleteAccount() async {
    try {
      // Show comprehensive warning dialog about account deletion consequences
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text(
            'Delete Account',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete your account?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'This action will permanently delete:',
                  style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                SizedBox(height: 8),
                // List of items that will be deleted
                Text('• Your profile and account data'),
                Text('• All your messages and chats'),
                Text('• Your friend connections and requests'),
                Text('• All app data associated with your account'),
                Text('• Your uploaded photos and files'),
                SizedBox(height: 16),
                Text(
                  '⚠️ This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'You will be asked to enter your password to confirm this action.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Keep Account'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Forever'),
            ),
          ],
        ),
        barrierDismissible: false, // Force user to make explicit choice
      );

      if (result == true) {
        // Call the AuthController's delete account method (which handles re-authentication)
        // AuthController manages the complex deletion process including password verification
        await _authController.deleteAccount();
      }
    } catch (e) {
      // Only show error if it's not already handled by AuthController
      // Avoid duplicate error messages for user-cancelled operations
      if (!e.toString().contains('User cancelled')) {
        Get.snackbar(
          'Error',
          'Failed to delete account: ${e.toString()}',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      }
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Format user's account creation date for display
  /// Provides user-friendly "Joined Month Year" format
  String getJoinedDate() {
    final user = _currentUser.value;
    if (user == null) return '';

    final date = user.createdAt;
    // Month abbreviations for consistent formatting
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return 'Joined ${months[date.month - 1]} ${date.year}';
  }

  /// Clear current error message
  /// Used for resetting error state when user dismisses errors
  void clearError() {
    _error.value = '';
  }
}
