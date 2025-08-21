import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/notifications_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/widgets/notification_item.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          Obx(() {
            final unreadCount = controller.getUnreadCount();
            return unreadCount > 0
                ? TextButton(
              onPressed: controller.markAllAsRead,
              child: const Text('Mark all read'),
            )
                : const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            final user = notification.data['senderId'] != null
                ? controller.getUser(notification.data['senderId'])
                : notification.data['userId'] != null
                ? controller.getUser(notification.data['userId'])
                : null;

            return NotificationItem(
              notification: notification,
              user: user,
              timeText: controller.getNotificationTimeText(notification.createdAt),
              icon: controller.getNotificationIcon(notification.type),
              iconColor: controller.getNotificationIconColor(notification.type),
              onTap: () => controller.handleNotificationTap(notification),
              onDelete: () => controller.deleteNotification(notification),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Text(
              'No notifications',
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
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