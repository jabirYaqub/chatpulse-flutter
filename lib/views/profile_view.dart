import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/profile_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

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
          Obx(
                () => TextButton(
              onPressed: controller.isEditing
                  ? controller.toggleEditing
                  : controller.toggleEditing,
              child: Text(
                controller.isEditing ? 'Cancel' : 'Edit',
                style: TextStyle(
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
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 32),
              _buildProfileForm(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Column(
      children: [
        Stack(
          children: [
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
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar(user);
                  },
                ),
              )
                  : _buildDefaultAvatar(user),
            )),
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
                    const PopupMenuItem(
                      value: 'update',
                      child: ListTile(
                        leading: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                        title: Text('Update Photo'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
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
        Text(
          user.displayName,
          style: Theme.of(
            Get.context!,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: Theme.of(
            Get.context!,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 8),
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
        Text(
          controller.getJoinedDate(),
          style: Theme.of(
            Get.context!,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
        ),
      ],
    );
  }

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

  Widget _buildProfileForm() {
    return Obx(
          () => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller.displayNameController,
                enabled: controller.isEditing,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.emailController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'Email cannot be changed',
                ),
              ),
              if (controller.isEditing) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        Card(
          child: Column(
            children: [
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
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.primaryColor),
                title: const Text('Sign Out'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: controller.signOut,
              ),
              const Divider(height: 1, color: Colors.grey),
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