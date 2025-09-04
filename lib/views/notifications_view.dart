import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/notifications_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/widgets/notification_item.dart';

/// GetView that displays the user's notification center
/// Features a list of notifications with interactive actions, empty state handling,
/// and bulk operations like "mark all as read" for managing notification status
class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        // Back navigation to return to previous screen
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          // Dynamic "Mark all read" button - only shown when unread notifications exist
          Obx(() {
            final unreadCount = controller.getUnreadCount();
            return unreadCount > 0
                ? TextButton(
              onPressed: controller.markAllAsRead,
              child: const Text('Mark all read'),
            )
                : const SizedBox.shrink(); // Hide when no unread notifications
          }),
        ],
      ),
      body: Obx(() {
        // Show empty state when no notifications exist
        if (controller.notifications.isEmpty) {
          return _buildEmptyState();
        }

        // Build scrollable list of notification items
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            // Extract user data from notification metadata
            // Different notification types store user IDs in different fields
            final user = notification.data['senderId'] != null
                ? controller.getUser(notification.data['senderId'])  // Friend requests, messages
                : notification.data['userId'] != null
                ? controller.getUser(notification.data['userId'])    // General user-related notifications
                : null;

            return NotificationItem(
              notification: notification,
              user: user,
              timeText: controller.getNotificationTimeText(notification.createdAt),
              // Dynamic styling based on notification type
              icon: controller.getNotificationIcon(notification.type),
              iconColor: controller.getNotificationIconColor(notification.type),
              // Action callbacks for user interactions
              onTap: () => controller.handleNotificationTap(notification),      // Navigate or perform action
              onDelete: () => controller.deleteNotification(notification),     // Remove notification
            );
          },
        );
      }),
    );
  }

  /// Builds the empty state display when no notifications exist
  /// Shows encouraging message about what notifications will contain
  /// @return Widget - The empty state interface
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Notification icon with circular background
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // Main heading for empty state
            Text(
              'No notifications',
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            // Descriptive text explaining what will appear here
            Text(
              'When you receive friend requests, messages, or other updates, they will appear here',
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
