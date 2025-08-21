import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/change_password_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());

    return Scaffold(
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
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
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
                Text(
                  'Update Your Password',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your current password and choose a new secure password',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Current Password Field
                Obx(
                      () => TextFormField(
                    controller: controller.currentPasswordController,
                    obscureText: controller.obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
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
                Obx(
                      () => TextFormField(
                    controller: controller.newPasswordController,
                    obscureText: controller.obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
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
                Obx(
                      () => TextFormField(
                    controller: controller.confirmPasswordController,
                    obscureText: controller.obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
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
                Obx(
                      () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : controller.changePassword,
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