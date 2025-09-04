import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/forgot_password_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

/// StatelessWidget that provides a password reset interface
/// Features a two-state UI: email input form and email sent confirmation
/// Uses GetX for state management and reactive UI updates
class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the forgot password controller using GetX dependency injection
    final controller = Get.put(ForgotPasswordController());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            // Form key for validation handling
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header section with back button and title
                Row(
                  children: [
                    IconButton(
                      onPressed: controller.goBackToLogin,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Forgot Password',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Descriptive subtitle aligned with the title
                Padding(
                  padding: const EdgeInsets.only(left: 56), // Align with title text
                  child: Text(
                    'Enter your email to receive a password reset link',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // Lock reset icon with circular background
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Dynamic content area - switches between email form and confirmation
                // Uses Obx for reactive updates when emailSent state changes
                Obx(() {
                  if (controller.emailSent) {
                    return _buildEmailSentContent(controller);
                  } else {
                    return _buildEmailForm(controller);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the initial email input form
  /// Contains email field, send button, and navigation back to login
  /// @param controller - The ForgotPasswordController managing this form
  /// @return Widget - The email input form widget tree
  Widget _buildEmailForm(ForgotPasswordController controller) {
    return Column(
      children: [
        // Email input field with validation
        TextFormField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
            hintText: 'Enter your email address',
          ),
          validator: controller.validateEmail,
        ),
        const SizedBox(height: 32),

        // Send reset link button with loading state
        // Uses Obx for reactive updates when loading state changes
        Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            // Disable button during loading to prevent multiple submissions
            onPressed: controller.isLoading ? null : controller.sendPasswordResetEmail,
            // Show loading spinner or send icon based on state
            icon: controller.isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.send),
            // Dynamic button text based on loading state
            label: Text(controller.isLoading ? 'Sending...' : 'Send Reset Link'),
          ),
        )),
        const SizedBox(height: 24),

        // Navigation link back to login screen
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Remember your password? ',
              style: Theme.of(Get.context!).textTheme.bodyMedium,
            ),
            GestureDetector(
              onTap: controller.goBackToLogin,
              child: Text(
                'Sign In',
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the email sent confirmation screen
  /// Displays success message, user's email, and action buttons
  /// @param controller - The ForgotPasswordController managing this state
  /// @return Widget - The email sent confirmation widget tree
  Widget _buildEmailSentContent(ForgotPasswordController controller) {
    return Column(
      children: [
        // Success message container with green styling
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // Email read icon indicating successful send
              const Icon(
                Icons.mark_email_read_rounded,
                size: 60,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: 16),

              // Success heading
              Text(
                'Email Sent!',
                style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Instructional text
              Text(
                'We\'ve sent a password reset link to:',
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Display the email address that received the reset link
              Text(
                controller.emailController.text,
                style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // Additional instructions for the user
              Text(
                'Check your email and follow the instructions to reset your password.',
                style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Resend email button (outlined style for secondary action)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.resendEmail,
            icon: const Icon(Icons.refresh),
            label: const Text('Resend Email'),
          ),
        ),
        const SizedBox(height: 16),

        // Back to login button (primary action)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.goBackToLogin,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Sign In'),
          ),
        ),
        const SizedBox(height: 24),

        // Helpful tip container with info styling
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Info icon for the tip
              const Icon(
                Icons.info_outline,
                color: AppTheme.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),

              // Tip text about checking spam folder
              Expanded(
                child: Text(
                  'Didn\'t receive the email? Check your spam folder or try again.',
                  style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
