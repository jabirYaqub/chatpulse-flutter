import 'package:flutter/material.dart';
import 'package:chat_app_flutter/models/notification_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

/// StatelessWidget that displays a single notification item in the notifications list
/// Features dynamic content based on notification type, read/unread visual indicators,
/// and interactive actions for tapping to view details or deleting the notification
class NotificationItem extends StatelessWidget {
  final NotificationModel notification;  // The notification data to display
  final UserModel? user;                 // Optional user data for personalized messages
  final String timeText;                 // Formatted time string for display
  final IconData icon;                   // Icon representing notification type
  final Color iconColor;                 // Color for the notification icon
  final VoidCallback onTap;              // Callback when notification is tapped
  final VoidCallback onDelete;           // Callback for deleting notification

  const NotificationItem({
    super.key,
    required this.notification,
    this.user,
    required this.timeText,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Different background color for unread notifications
      color: notification.isRead ? null : AppTheme.primaryColor.withOpacity(0.05),
      child: InkWell(
        onTap: onTap, // Handle notification tap to view details or take action
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Notification type icon with colored background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Notification content area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with unread indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              // Bold text for unread notifications
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                        ),
                        // Blue dot indicator for unread notifications
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Notification body text with personalized content
                    Text(
                      _getNotificationBody(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Timestamp of the notification
                    Text(
                      timeText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button for removing notification
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.close,
                  color: AppTheme.textSecondaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generates personalized notification body text based on notification type and user data
  /// Creates user-friendly messages by incorporating the related user's name when available
  /// @return String - Personalized notification body text
  String _getNotificationBody() {
    String body = notification.body;

    // Personalize notification messages when user data is available
    if (user != null) {
      switch (notification.type) {
        case NotificationType.friendRequest:
          body = '${user!.displayName} sent you a friend request';
          break;
        case NotificationType.friendRequestAccepted:
          body = '${user!.displayName} accepted your friend request';
          break;
        case NotificationType.friendRequestDeclined:
          body = '${user!.displayName} declined your friend request';
          break;
        case NotificationType.newMessage:
          body = '${user!.displayName} sent you a message';
          break;
        case NotificationType.friendRemoved:
          body = 'You are no longer friends with ${user!.displayName}';
          break;
      }
    }

    return body;
  }
}
