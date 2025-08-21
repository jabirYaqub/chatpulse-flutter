import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/services/auth_service.dart';

// The ForgotPasswordController is a GetX controller that handles the logic
// for the password reset flow. It manages user input, communicates with the
// authentication service, and updates the UI state accordingly.
class ForgotPasswordController extends GetxController {
  // Dependency injection: an instance of AuthService is used to perform
  // the actual password reset operation.
  final AuthService _authService = AuthService();

  // A TextEditingController to manage the text input for the user's email.
  final TextEditingController emailController = TextEditingController();
  // A GlobalKey to access and validate the state of the Form widget.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Reactive state variables for the UI. These are observable and
  // trigger UI updates when their values change.
  final RxBool _isLoading = false.obs; // Tracks if an operation is in progress.
  final RxString _error = ''.obs; // Stores any error messages.
  final RxBool _emailSent = false.obs; // Tracks if the reset email has been sent.

  // Public getters to provide read-only access to the reactive state.
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get emailSent => _emailSent.value;

  /// Disposes of the TextEditingController when the controller is no longer
  /// needed to prevent memory leaks.
  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  /// Sends a password reset email to the user's provided email address.
  Future<void> sendPasswordResetEmail() async {
    // First, validate the form using the global key. If it's invalid,
    // the method stops and displays validation errors on the form fields.
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      // Call the authentication service to send the password reset email.
      await _authService.sendPasswordResetEmail(emailController.text.trim());

      _emailSent.value = true; // Set state to indicate success.
      // Show a success snackbar to the user.
      Get.snackbar(
        'Success',
        'Password reset email sent to ${emailController.text.trim()}',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      _error.value = e.toString(); // Store the error message.
      // Show a user-friendly error snackbar.
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      // Ensure the loading state is reset, regardless of success or failure.
      _isLoading.value = false;
    }
  }

  /// Navigates the user back to the login screen.
  void goBackToLogin() {
    Get.back();
  }

  /// Resets the `_emailSent` state and re-sends the password reset email.
  void resendEmail() {
    _emailSent.value = false;
    sendPasswordResetEmail();
  }

  /// A validation function for the email input field.
  String? validateEmail(String? value) {
    // Check if the input is empty.
    if (value?.isEmpty ?? true) {
      return 'Please enter your email';
    }
    // Use GetX's utility function to check if the email format is valid.
    if (!GetUtils.isEmail(value!)) {
      return 'Please enter a valid email';
    }
    return null; // Return null if the input is valid.
  }

  /// Clears the current error message.
  void clearError() {
    _error.value = '';
  }
}