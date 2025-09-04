import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/change_password_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

/// StatelessWidget that provides a user interface for changing passwords
/// Uses GetX for state management and reactive UI updates
/// Features form validation, password visibility toggles, and loading states
class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller using GetX dependency injection
    final controller = Get.put(ChangePasswordController());

    return Scaffold(
      // App bar with title and back navigation
      appBar: AppBar(
        title: const Text('Change Password'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            // Form key for validation handling
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Security icon container with circular background
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Main heading text
                Text(
                  'Update Your Password',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Descriptive subtext providing user guidance
                Text(
                  'Enter your current password and choose a new secure password',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Current Password Field
                // Uses Obx for reactive updates when visibility state changes
                Obx(
                      () => TextFormField(
                    controller: controller.currentPasswordController,
                    obscureText: controller.obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      // Toggle button for password visibility
                      suffixIcon: IconButton(
                        icon: Icon(
                          // FIXED: Correct eye icon logic
                          controller.obscureCurrentPassword
                              ? Icons.visibility_off_outlined  // Password hidden = eye with slash
                              : Icons.visibility_outlined,     // Password visible = regular eye
                        ),
                        onPressed: controller.toggleCurrentPasswordVisibility,
                      ),
                      hintText: 'Enter your current password',
                    ),
                    validator: controller.validateCurrentPassword,
                  ),
                ),
                const SizedBox(height: 20),

                // New Password Field
                // Reactive widget that updates when password visibility changes
                Obx(
                      () => TextFormField(
                    controller: controller.newPasswordController,
                    obscureText: controller.obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      // Eye icon toggles between visible/hidden states
                      suffixIcon: IconButton(
                        icon: Icon(
                          // FIXED: Correct eye icon logic
                          controller.obscureNewPassword
                              ? Icons.visibility_off_outlined  // Password hidden = eye with slash
                              : Icons.visibility_outlined,     // Password visible = regular eye
                        ),
                        onPressed: controller.toggleNewPasswordVisibility,
                      ),
                      hintText: 'Enter your new password',
                    ),
                    validator: controller.validateNewPassword,
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                // Ensures user enters the same password twice for confirmation
                Obx(
                      () => TextFormField(
                    controller: controller.confirmPasswordController,
                    obscureText: controller.obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      // Visibility toggle for confirm password field
                      suffixIcon: IconButton(
                        icon: Icon(
                          // FIXED: Correct eye icon logic
                          controller.obscureConfirmPassword
                              ? Icons.visibility_off_outlined  // Password hidden = eye with slash
                              : Icons.visibility_outlined,     // Password visible = regular eye
                        ),
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                      hintText: 'Confirm your new password',
                    ),
                    validator: controller.validateConfirmPassword,
                  ),
                ),
                const SizedBox(height: 40),

                // Update Button
                // Reactive button that shows loading state and disables during processing
                Obx(
                      () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      // Disable button during loading to prevent multiple submissions
                      onPressed: controller.isLoading
                          ? null
                          : controller.changePassword,
                      // Show loading spinner or security icon based on state
                      icon: controller.isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.security),
                      // Dynamic button text based on loading state
                      label: Text(
                        controller.isLoading
                            ? 'Updating...'
                            : 'Update Password',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
