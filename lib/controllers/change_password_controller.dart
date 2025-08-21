import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';

// ChangePasswordController is a GetX controller responsible for the logic of the
// change password screen. It handles form validation, user re-authentication,
// password updates, and provides reactive state for the UI.
class ChangePasswordController extends GetxController {
  // A dependency on AuthController is used to access authenticated user data.
  final AuthController _authController = Get.find<AuthController>();

  // Text editing controllers for the input fields. These allow us to read
  // and manage the text entered by the user.
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  // A global key for the form state, used to validate all form fields at once.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Reactive state variables for managing UI state.
  final RxBool _isLoading = false.obs; // Tracks if an operation is in progress.
  final RxString _error = ''.obs; // Stores error messages for display.
  // Reactive booleans to toggle password visibility in the text fields.
  final RxBool _obscureCurrentPassword = true.obs;
  final RxBool _obscureNewPassword = true.obs;
  final RxBool _obscureConfirmPassword = true.obs;

  // Public getters to expose the reactive state to the UI.
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get obscureCurrentPassword => _obscureCurrentPassword.value;
  bool get obscureNewPassword => _obscureNewPassword.value;
  bool get obscureConfirmPassword => _obscureConfirmPassword.value;

  /// Disposes of the text editing controllers when the controller is closed
  /// to prevent memory leaks.
  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Toggles the visibility of the current password field.
  void toggleCurrentPasswordVisibility() {
    _obscureCurrentPassword.value = !_obscureCurrentPassword.value;
  }

  /// Toggles the visibility of the new password field.
  void toggleNewPasswordVisibility() {
    _obscureNewPassword.value = !_obscureNewPassword.value;
  }

  /// Toggles the visibility of the confirm password field.
  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
  }

  /// The main method to handle the password change process.
  Future<void> changePassword() async {
    // Validate the form before proceeding. If validation fails, exit the function.
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // If no user is logged in, throw an error.
        throw Exception('No user logged in');
      }

      // Step 1: Re-authenticate the user with their current password.
      // Firebase requires this step for security before a password can be updated.
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Step 2: Update the password with the new password.
      await user.updatePassword(newPasswordController.text);

      // Show a success message to the user using GetX's snackbar.
      Get.snackbar(
        'Success',
        'Password has been updated successfully',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );

      // Step 3: Clear the input fields after a successful update.
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      // Add a small delay to allow the user to see the snackbar before navigating back.
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Navigate back to the previous screen (e.g., the profile page).
      Get.back();
    } on FirebaseAuthException catch (e) {
      // Catch and handle specific Firebase authentication errors.
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Current password is incorrect';
          break;
        case 'weak-password':
          errorMessage = 'New password is too weak';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please sign out and sign in again before changing password';
          break;
        default:
          errorMessage = 'Failed to change password: ${e.message}';
      }
      _error.value = errorMessage;
      // Show an informative error snackbar.
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } catch (e) {
      // Catch any other general exceptions.
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      // Ensure the loading state is always set to false after the operation completes.
      _isLoading.value = false;
    }
  }

  // --- Form Validation Methods ---
  // These methods are used by the TextFormField widgets to validate user input.

  /// Validates the current password field.
  String? validateCurrentPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter your current password';
    }
    return null;
  }

  /// Validates the new password field.
  String? validateNewPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter a new password';
    }
    // Check for minimum length.
    if (value!.length < 6) {
      return 'Password must be at least 6 characters';
    }
    // Ensure the new password is not the same as the current one.
    if (value == currentPasswordController.text) {
      return 'New password must be different from current password';
    }
    return null;
  }

  /// Validates the confirm password field.
  String? validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please confirm your new password';
    }
    // Check if the confirmed password matches the new password.
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Clears the current error message.
  void clearError() {
    _error.value = '';
  }
}