import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/services/auth_service.dart';

/// The ForgotPasswordController is a GetX controller that handles the logic
/// for the password reset flow. It manages user input, communicates with the
/// authentication service, and updates the UI state accordingly.
///
/// This controller is responsible for:
/// - Email validation for password reset requests
/// - Sending password reset emails through Firebase Auth
/// - Managing loading states during email sending operations
/// - Handling success and error feedback to users
/// - Providing resend functionality for failed attempts
/// - Navigation back to login screen after completion
class ForgotPasswordController extends GetxController {

  // ==================== DEPENDENCIES ====================

  /// Dependency injection: an instance of AuthService is used to perform
  /// the actual password reset operation through Firebase Auth.
  final AuthService _authService = AuthService();

  // ==================== FORM CONTROLLERS ====================

  /// A TextEditingController to manage the text input for the user's email.
  /// This allows reading, clearing, and managing the email input field.
  final TextEditingController emailController = TextEditingController();

  /// A GlobalKey to access and validate the state of the Form widget.
  /// This enables form-wide validation by calling formKey.currentState!.validate()
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ==================== REACTIVE STATE VARIABLES ====================

  /// Reactive state variables for the UI. These are observable and
  /// trigger UI updates when their values change using GetX's reactive system.

  /// Tracks if a password reset email sending operation is in progress
  final RxBool _isLoading = false.obs;

  /// Stores any error messages that occur during the reset process
  final RxString _error = ''.obs;

  /// Tracks if the reset email has been successfully sent to the user
  final RxBool _emailSent = false.obs;

  // ==================== PUBLIC GETTERS ====================

  /// Public getters to provide read-only access to the reactive state.
  /// These expose the current state without allowing external modification.

  /// Returns true if an email sending operation is currently in progress
  bool get isLoading => _isLoading.value;

  /// Returns the current error message or empty string if no error
  String get error => _error.value;

  /// Returns true if a password reset email has been successfully sent
  bool get emailSent => _emailSent.value;

  // ==================== LIFECYCLE METHODS ====================

  /// Disposes of the TextEditingController when the controller is no longer
  /// needed to prevent memory leaks. Called automatically by GetX.
  @override
  void onClose() {
    // Clean up the email controller to free memory
    emailController.dispose();
    super.onClose();
  }

  // ==================== PASSWORD RESET OPERATIONS ====================

  /// Sends a password reset email to the user's provided email address.
  /// This method handles the complete flow from validation to user feedback.
  Future<void> sendPasswordResetEmail() async {
    // First, validate the form using the global key. If it's invalid,
    // the method stops and displays validation errors on the form fields.
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      // Set loading state to show progress indicators in UI
      _isLoading.value = true;
      // Clear any previous error messages
      _error.value = '';

      // Call the authentication service to send the password reset email.
      // This triggers Firebase Auth to send an email with reset instructions.
      await _authService.sendPasswordResetEmail(emailController.text.trim());

      // Set state to indicate successful email sending
      _emailSent.value = true;

      // Show a success snackbar to the user with confirmation details.
      Get.snackbar(
        'Success',
        'Password reset email sent to ${emailController.text.trim()}',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      // Store the error message for potential UI display
      _error.value = e.toString();

      // Show a user-friendly error snackbar with red styling.
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      // Ensure the loading state is reset, regardless of success or failure.
      // This prevents UI from being stuck in loading state.
      _isLoading.value = false;
    }
  }

  /// Resets the `_emailSent` state and re-sends the password reset email.
  /// This allows users to retry if the first attempt failed or if they didn't receive the email.
  void resendEmail() {
    // Reset the email sent flag to allow showing the form again if needed
    _emailSent.value = false;
    // Trigger another password reset email send
    sendPasswordResetEmail();
  }

  // ==================== NAVIGATION METHODS ====================

  /// Navigates the user back to the login screen.
  /// This is typically called after successful email sending or if user cancels.
  void goBackToLogin() {
    // Use GetX navigation to return to previous screen
    Get.back();
  }

  // ==================== FORM VALIDATION ====================

  /// A validation function for the email input field.
  /// This is called automatically by Flutter's form validation system.
  String? validateEmail(String? value) {
    // Check if the input is empty or null.
    if (value?.isEmpty ?? true) {
      return 'Please enter your email';
    }

    // Use GetX's utility function to check if the email format is valid.
    // This validates against standard email format patterns.
    if (!GetUtils.isEmail(value!)) {
      return 'Please enter a valid email';
    }

    // Return null if the input passes all validation checks.
    return null;
  }

  // ==================== UTILITY METHODS ====================

  /// Clears the current error message.
  /// Useful for resetting error state when user starts a new operation
  /// or when manually dismissing error messages.
  void clearError() {
    _error.value = '';
  }
}
