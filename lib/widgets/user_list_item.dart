import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/controllers/users_list_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

class UserListItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final UsersListController controller;

  const UserListItem({
    super.key,
    required this.user,
    required this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final relationshipStatus = controller.getUserRelationshipStatus(user.id);

      // Don't show users who are already friends
      if (relationshipStatus == UserRelationshipStatus.friends) {
        return const SizedBox.shrink();
      }

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile picture with online status
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryColor,
                    child: user.photoURL.isNotEmpty
                        ? ClipOval(
                      child: Image.network(
                        user.photoURL,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildLoadingAvatar();
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      ),
                    )
                        : _buildDefaultAvatar(),
                  ),
                  // Online status indicator
                  if (user.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.successColor,
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Last seen status
                    Text(
                      controller.getLastSeenText(user),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: user.isOnline
                            ? AppTheme.successColor
                            : AppTheme.textSecondaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _buildActionButton(relationshipStatus),
                  if (relationshipStatus ==
                      UserRelationshipStatus.friendRequestReceived) ...[
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () => controller.declineFriendRequest(user),
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text(
                        'Decline',
                        style: TextStyle(fontSize: 10),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 24),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // Default avatar with user initials
  Widget _buildDefaultAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Text(
          user.displayName.isNotEmpty
              ? user.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Loading avatar with shimmer effect
  Widget _buildLoadingAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(UserRelationshipStatus relationshipStatus) {
    switch (relationshipStatus) {
      case UserRelationshipStatus.none:
        return ElevatedButton.icon(
          onPressed: () => controller.handleRelationshipAction(user),
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Add Friend', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

      case UserRelationshipStatus.friendRequestSent:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Text(
                    'Request Sent',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => _showCancelRequestDialog(),
              icon: const Icon(Icons.cancel_outlined, size: 14),
              label: const Text('Cancel', style: TextStyle(fontSize: 10)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        );

      case UserRelationshipStatus.friendRequestReceived:
        return ElevatedButton.icon(
          onPressed: () => controller.handleRelationshipAction(user),
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Accept', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

      case UserRelationshipStatus.blocked:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.1),
            border: Border.all(color: AppTheme.errorColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 16, color: AppTheme.errorColor),
              SizedBox(width: 6),
              Text(
                'Blocked',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      case UserRelationshipStatus.friends:
      // This case should never be reached due to the check at the beginning
        return const SizedBox.shrink();
    }
  }

  void _showCancelRequestDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Friend Request'),
        content: Text(
          'Are you sure you want to cancel the friend request to ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelFriendRequest(user);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }
}