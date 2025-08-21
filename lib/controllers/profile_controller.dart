import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/services/storage_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';

class ProfileController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final AuthController _authController = Get.find<AuthController>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final RxBool _isLoading = false.obs;
  final RxBool _isEditing = false.obs;
  final RxString _error = ''.obs;
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxBool _isUploadingImage = false.obs;

  bool get isLoading => _isLoading.value;
  bool get isEditing => _isEditing.value;
  String get error => _error.value;
  UserModel? get currentUser => _currentUser.value;
  bool get isUploadingImage => _isUploadingImage.value;

  @override
  void onInit() {
    super.onInit();
    print('🔄 ProfileController: onInit called');
    _loadUserData();
  }

  @override
  void onClose() {
    displayNameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  void _loadUserData() {
    final currentUserId = _authController.user?.uid;
    print('👤 ProfileController: Loading user data for ID: $currentUserId');

    if (currentUserId != null) {
      // First, try to get user from AuthController
      final authUser = _authController.userModel;
      if (authUser != null) {
        print('✅ ProfileController: Found user in AuthController: ${authUser.displayName}');
        _currentUser.value = authUser;
        displayNameController.text = authUser.displayName;
        emailController.text = authUser.email;
        return;
      }

      // If not found in AuthController, try Firestore stream
      print('🔍 ProfileController: Trying Firestore stream...');
      try {
        _currentUser.bindStream(_firestoreService.getUserStream(currentUserId));

        ever(_currentUser, (UserModel? user) {
          if (user != null) {
            print('✅ ProfileController: User data loaded from Firestore: ${user.displayName}');
            displayNameController.text = user.displayName;
            emailController.text = user.email;
          } else {
            print('❌ ProfileController: No user data found in Firestore');
            _tryCreateUserFromFirebaseAuth();
          }
        });

        // Add timeout to detect if stream is not working
        Future.delayed(const Duration(seconds: 3), () {
          if (_currentUser.value == null) {
            print('⏰ ProfileController: Timeout - trying alternative method');
            _tryCreateUserFromFirebaseAuth();
          }
        });

      } catch (e) {
        print('❌ ProfileController: Error binding to Firestore stream: $e');
        _tryCreateUserFromFirebaseAuth();
      }
    } else {
      print('❌ ProfileController: No current user ID found');
      _error.value = 'No user logged in';
    }
  }

  // Fallback method to create user from Firebase Auth data
  void _tryCreateUserFromFirebaseAuth() {
    print('🔧 ProfileController: Trying to create user from Firebase Auth data');

    final firebaseUser = _authController.user;
    if (firebaseUser != null) {
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
      _currentUser.value = fallbackUser;
      displayNameController.text = fallbackUser.displayName;
      emailController.text = fallbackUser.email;

      // Try to save this user to Firestore
      _saveUserToFirestore(fallbackUser);
    } else {
      print('❌ ProfileController: No Firebase user found either');
      _error.value = 'Unable to load user data';
    }
  }

  // Save user to Firestore
  Future<void> _saveUserToFirestore(UserModel user) async {
    try {
      print('💾 ProfileController: Saving user to Firestore');
      await _firestoreService.updateUser(user);
      print('✅ ProfileController: User saved to Firestore successfully');
    } catch (e) {
      print('❌ ProfileController: Failed to save user to Firestore: $e');
      // Try creating user instead of updating
      try {
        await _firestoreService.createUser(user);
        print('✅ ProfileController: User created in Firestore successfully');
      } catch (createError) {
        print('❌ ProfileController: Failed to create user in Firestore: $createError');
      }
    }
  }

  // Force reset method to fix stuck loading
  void forceReset() {
    print('🔄 ProfileController: Force reset called');
    _isLoading.value = false;
    _isUploadingImage.value = false;
    _error.value = '';
    _currentUser.value = null;
    _loadUserData();
  }

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;

    if (!_isEditing.value) {
      // Reset fields if canceling edit
      final user = _currentUser.value;
      if (user != null) {
        displayNameController.text = user.displayName;
        emailController.text = user.email;
      }
    }
  }

  Future<void> updateProfile() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final user = _currentUser.value;
      if (user == null) return;

      final updatedUser = user.copyWith(
        displayName: displayNameController.text.trim(),
      );

      try {
        await _firestoreService.updateUser(updatedUser);
      } catch (e) {
        // If update fails, try to create the user
        await _firestoreService.createUser(updatedUser);
      }

      // Update auth controller's user model
      _authController.updateUserModel(updatedUser);
      _currentUser.value = updatedUser;

      _isEditing.value = false;
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  // FIXED: Profile picture upload with better error handling
  Future<void> updateProfilePicture() async {
    try {
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

        final XFile? pickedFile = await _imagePicker.pickImage(
          source: result,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          print('📷 ProfileController: Uploading image...');
          final imageFile = File(pickedFile.path);
          final imageUrl = await _storageService.uploadImage(imageFile);
          print('✅ ProfileController: Image uploaded: $imageUrl');

          final user = _currentUser.value;
          if (user != null) {
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

            // Update auth controller's user model
            _authController.updateUserModel(updatedUser);

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
      Get.snackbar(
        'Error',
        'Failed to update profile picture. Please try again.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      _isUploadingImage.value = false;
    }
  }

  Future<void> removeProfilePicture() async {
    try {
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
          final updatedUser = user.copyWith(photoURL: '');

          try {
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

  Future<void> signOut() async {
    try {
      await _authController.signOut();
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: ${e.toString()}');
    }
  }

  // UPDATED: Enhanced delete account with comprehensive warning
  Future<void> deleteAccount() async {
    try {
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
        barrierDismissible: false,
      );

      if (result == true) {
        // Call the AuthController's delete account method (which handles re-authentication)
        await _authController.deleteAccount();
      }
    } catch (e) {
      // Only show error if it's not already handled by AuthController
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

  String getJoinedDate() {
    final user = _currentUser.value;
    if (user == null) return '';

    final date = user.createdAt;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return 'Joined ${months[date.month - 1]} ${date.year}';
  }

  void clearError() {
    _error.value = '';
  }
}