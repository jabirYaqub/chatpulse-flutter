import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';

/// ChangePasswordController is a GetX controller responsible for the logic of the
/// change password screen. It handles form validation, user re-authentication,
/// password updates, and provides reactive state for the UI.
///
/// This controller manages:
/// - Form state and validation for password change form
/// - Password visibility toggles for security and usability
/// - Firebase re-authentication before password updates
/// - Error handling with user-friendly messages
/// - Loading states during password update operations
class ChangePasswordController extends GetxController {

  // ==================== DEPENDENCIES ====================

  /// A dependency on AuthController is used to access authenticated user data.
  /// Using Get.find() ensures we get the existing instance from GetX dependency injection.
  final AuthController _authController = Get.find<AuthController>();

  // ==================== FORM CONTROLLERS ====================

  /// Text editing controllers for the input fields. These allow us to read
  /// and manage the text entered by the user in each password field.

  /// Controller for the current password input field
  final TextEditingController currentPasswordController = TextEditingController();

  /// Controller for the new password input field
  final TextEditingController newPasswordController = TextEditingController();

  /// Controller for the confirm password input field
  final TextEditingController confirmPasswordController = TextEditingController();

  /// A global key for the form state, used to validate all form fields at once.
  /// This enables calling formKey.currentState!.validate() to trigger validation
  /// on all TextFormField widgets within the form.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ==================== REACTIVE STATE VARIABLES ====================

  /// Reactive state variables for managing UI state using GetX observables.
  /// These automatically update the UI when their values change.

  /// Tracks if a password change operation is in progress (shows loading indicators)
  final RxBool _isLoading = false.obs;

  /// Stores error messages for display to the user
  final RxString _error = ''.obs;

  // Password visibility state management
  /// Controls whether the current password field shows actual characters or dots
  final RxBool _obscureCurrentPassword = true.obs;

  /// Controls whether the new password field shows actual characters or dots
  final RxBool _obscureNewPassword = true.obs;

  /// Controls whether the confirm password field shows actual characters or dots
  final RxBool _obscureConfirmPassword = true.obs;

  // ==================== PUBLIC GETTERS ====================

  /// Public getters to expose the reactive state to the UI.
  /// These provide a clean API for accessing state without exposing Rx objects directly.

  /// Returns true if a password change operation is currently in progress
  bool get isLoading => _isLoading.value;

  /// Returns the current error message or empty string if no error
  String get error => _error.value;

  /// Returns true if current password should be hidden (showing dots instead of text)
  bool get obscureCurrentPassword => _obscureCurrentPassword.value;

  /// Returns true if new password should be hidden (showing dots instead of text)
  bool get obscureNewPassword => _obscureNewPassword.value;

  /// Returns true if confirm password should be hidden (showing dots instead of text)
  bool get obscureConfirmPassword => _obscureConfirmPassword.value;

  // ==================== LIFECYCLE METHODS ====================

  /// Disposes of the text editing controllers when the controller is closed
  /// to prevent memory leaks. This is called automatically by GetX when the
  /// controller is removed from memory.
  @override
  void onClose() {
    // Dispose all text controllers to free up memory
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    // Call parent dispose method
    super.onClose();
  }

  // ==================== PASSWORD VISIBILITY METHODS ====================

  /// Toggles the visibility of the current password field.
  /// Switches between showing actual characters and showing dots for security.
  void toggleCurrentPasswordVisibility() {
    _obscureCurrentPassword.value = !_obscureCurrentPassword.value;
  }

  /// Toggles the visibility of the new password field.
  /// Allows users to see what they're typing when creating a new password.
  void toggleNewPasswordVisibility() {
    _obscureNewPassword.value = !_obscureNewPassword.value;
  }

  /// Toggles the visibility of the confirm password field.
  /// Helps users verify they've typed their new password correctly.
  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
  }

  // ==================== PASSWORD CHANGE LOGIC ====================

  /// The main method to handle the password change process.
  /// This is a multi-step process that includes validation, re-authentication,
  /// password update, and user feedback. Firebase requires re-authentication
  /// for security before allowing password changes.
  Future<void> changePassword() async {
    // Validate the form before proceeding. If validation fails, exit the function.
    // This triggers all validator functions on the form fields
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      // Set loading state to show progress indicators in UI
      _isLoading.value = true;
      // Clear any previous error messages
      _error.value = '';

      // Get the current authenticated user from Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // If no user is logged in, throw an error.
        // This shouldn't happen in normal flow but provides safety
        throw Exception('No user logged in');
      }

      // Step 1: Re-authenticate the user with their current password.
      // Firebase requires this step for security before a password can be updated.
      // This ensures the user knows their current password and has active session.
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Step 2: Update the password with the new password.
      // This actually changes the user's password in Firebase Auth
      await user.updatePassword(newPasswordController.text);

      // Show a success message to the user using GetX's snackbar.
      // Styled with green colors to indicate success
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
      // This prevents sensitive password data from remaining in memory
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      // Add a small delay to allow the user to see the snackbar before navigating back.
      // This improves user experience by ensuring they see the success message
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Navigate back to the previous screen (e.g., the profile page).
      // Using Get.back() returns to the previous route in the navigation stack
      Get.back();
    } on FirebaseAuthException catch (e) {
      // Catch and handle specific Firebase authentication errors.
      // Different error codes require different user-friendly messages
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
        // User entered incorrect current password
          errorMessage = 'Current password is incorrect';
          break;
        case 'weak-password':
        // New password doesn't meet Firebase's security requirements
          errorMessage = 'New password is too weak';
          break;
        case 'requires-recent-login':
        // User's session is too old for this security-sensitive operation
          errorMessage = 'Please sign out and sign in again before changing password';
          break;
        default:
        // Fallback for any other Firebase Auth errors
          errorMessage = 'Failed to change password: ${e.message}';
      }
      // Store error for potential UI display
      _error.value = errorMessage;
      // Show an informative error snackbar with red styling
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
      // Catch any other general exceptions not covered by FirebaseAuthException.
      // This provides a safety net for unexpected errors
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
      // This happens regardless of success or failure, ensuring UI returns to normal state
      _isLoading.value = false;
    }
  }

  // ==================== FORM VALIDATION METHODS ====================

  /// These methods are used by the TextFormField widgets to validate user input.
  /// They return null if validation passes, or an error message string if validation fails.
  /// Flutter's form validation system calls these methods automatically.

  /// Validates the current password field.
  /// Ensures the user has entered their current password before proceeding.
  String? validateCurrentPassword(String? value) {
    // Check if the field is empty or null
    if (value?.isEmpty ?? true) {
      return 'Please enter your current password';
    }
    // Validation passed
    return null;
  }

  /// Validates the new password field.
  /// Ensures the new password meets security requirements and is different from current.
  String? validateNewPassword(String? value) {
    // Check if the field is empty or null
    if (value?.isEmpty ?? true) {
      return 'Please enter a new password';
    }
    // Check for minimum length requirement.
    // 6 characters is Firebase Auth's minimum requirement
    if (value!.length < 6) {
      return 'Password must be at least 6 characters';
    }
    // Ensure the new password is not the same as the current one.
    // This prevents users from "changing" to the same password
    if (value == currentPasswordController.text) {
      return 'New password must be different from current password';
    }
    // Validation passed
    return null;
  }

  /// Validates the confirm password field.
  /// Ensures the user has correctly confirmed their new password.
  String? validateConfirmPassword(String? value) {
    // Check if the field is empty or null
    if (value?.isEmpty ?? true) {
      return 'Please confirm your new password';
    }
    // Check if the confirmed password matches the new password.
    // This prevents typos in the new password by requiring confirmation
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    // Validation passed
    return null;
  }

  // ==================== UTILITY METHODS ====================

  /// Clears the current error message.
  /// Useful for resetting error state when user starts a new operation
  /// or when dismissing error messages manually.
  void clearError() {
    _error.value = '';
  }
}
