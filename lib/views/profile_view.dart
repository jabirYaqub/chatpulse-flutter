import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/profile_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

/// GetView that displays the user's profile screen with edit capabilities
/// Features profile picture management, personal information editing,
/// account actions, and settings navigation for complete profile management
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true, // Center the title
        leading: const SizedBox(), // Remove back button when accessed from main navigation
        actions: [
          // Dynamic edit/cancel button that changes based on editing state
          Obx(
                () => TextButton(
              onPressed: controller.isEditing
                  ? controller.toggleEditing
                  : controller.toggleEditing,
              child: Text(
                controller.isEditing ? 'Cancel' : 'Edit',
                style: TextStyle(
                  // Red color for cancel, blue for edit
                  color: controller.isEditing
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final user = controller.currentUser;
        // Show loading indicator while user data is being fetched
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile picture and basic info section
              _buildProfileHeader(user),
              const SizedBox(height: 32),
              // Editable form for personal information
              _buildProfileForm(),
              const SizedBox(height: 32),
              // Account actions and app info section
              _buildActionButtons(),
            ],
          ),
        );
      }),
    );
  }

  /// Builds the profile header with avatar, name, email, and status
  /// Features interactive profile picture with update/remove options
  /// @param user - The user model containing profile information
  /// @return Widget - Complete profile header section
  Widget _buildProfileHeader(dynamic user) {
    return Column(
      children: [
        // Profile picture with camera overlay button
        Stack(
          children: [
            // Main profile avatar with loading state
            Obx(() => CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryColor,
              child: controller.isUploadingImage
                  ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              )
                  : user.photoURL.isNotEmpty
                  ? ClipOval(
                child: Image.network(
                  user.photoURL,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  // Fallback to initials if image fails to load
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar(user);
                  },
                ),
              )
                  : _buildDefaultAvatar(user),
            )),
            // Camera button overlay for profile picture actions
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'update':
                        controller.updateProfilePicture();
                        break;
                      case 'remove':
                        controller.removeProfilePicture();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    // Update photo option
                    const PopupMenuItem(
                      value: 'update',
                      child: ListTile(
                        leading: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                        title: Text('Update Photo'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    // Remove photo option (only shown if user has a photo)
                    if (user.photoURL.isNotEmpty)
                      const PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                          title: Text('Remove Photo'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // User's display name
        Text(
          user.displayName,
          style: Theme.of(
            Get.context!,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        // User's email address
        Text(
          user.email,
          style: Theme.of(
            Get.context!,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 8),
        // Online/offline status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: user.isOnline
                ? AppTheme.successColor.withOpacity(0.1)
                : AppTheme.textSecondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status dot indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: user.isOnline
                      ? AppTheme.successColor
                      : AppTheme.textSecondaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              // Status text
              Text(
                user.isOnline ? 'Online' : 'Offline',
                style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                  color: user.isOnline
                      ? AppTheme.successColor
                      : AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Account creation date
        Text(
          controller.getJoinedDate(),
          style: Theme.of(
            Get.context!,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
        ),
      ],
    );
  }

  /// Builds the default avatar with user's initials
  /// Used when no profile picture is available or image fails to load
  /// @param user - The user model containing display name
  /// @return Widget - Text avatar with initials
  Widget _buildDefaultAvatar(dynamic user) {
    return Text(
      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Builds the editable profile form section
  /// Contains personal information fields with edit mode toggle
  /// @return Widget - Profile editing form
  Widget _buildProfileForm() {
    return Obx(
          () => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section heading
              Text(
                'Personal Information',
                style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              // Display name field - editable when in edit mode
              TextFormField(
                controller: controller.displayNameController,
                enabled: controller.isEditing,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
              ),
              const SizedBox(height: 16),
              // Email field - always disabled (cannot be changed)
              TextFormField(
                controller: controller.emailController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'Email cannot be changed',
                ),
              ),
              // Save button - only shown when editing
              if (controller.isEditing) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // Disable during loading to prevent multiple submissions
                    onPressed: controller.isLoading
                        ? null
                        : controller.updateProfile,
                    child: controller.isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the action buttons section for account management
  /// Contains navigation to settings and account actions like sign out
  /// @return Widget - Action buttons and app version info
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Account actions card
        Card(
          child: Column(
            children: [
              // Change password navigation
              ListTile(
                leading: const Icon(
                  Icons.security,
                  color: AppTheme.primaryColor,
                ),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Get.toNamed('/change-password'),
              ),
              const Divider(height: 1, color: Colors.grey),
              // Sign out action
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.primaryColor),
                title: const Text('Sign Out'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: controller.signOut,
              ),
              const Divider(height: 1, color: Colors.grey),
              // Delete account action (destructive)
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: AppTheme.errorColor,
                ),
                title: const Text('Delete Account'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: controller.deleteAccount,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // App version information
        Text(
          'ChatApp v1.0.0',
          style: Theme.of(
            Get.context!,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
        ),
      ],
    );
  }
}
