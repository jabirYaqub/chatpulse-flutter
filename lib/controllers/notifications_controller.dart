import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/models/notification_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

// NotificationsController manages all logic related to the user's notifications.
// It handles fetching notifications, marking them as read, and navigating
// the user to the appropriate screen when a notification is tapped.
class NotificationsController extends GetxController {
  // Dependencies are injected for a clean, modular design.
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  // Reactive state variables to manage the UI.
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs; // A stream of notifications for the user.
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs; // A cache of all users for easy lookup.
  final RxBool _isLoading = false.obs; // Tracks global loading state.
  final RxString _error = ''.obs; // Stores any error messages.

  // Public getters to provide read-only access to the reactive state.
  List<NotificationModel> get notifications => _notifications;
  Map<String, UserModel> get users => _users;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  /// Called automatically by GetX when the controller is first created.
  @override
  void onInit() {
    super.onInit();
    // Start listening to data streams.
    _loadNotifications();
    _loadUsers();
  }

  /// Binds the `_notifications` list to a real-time stream from Firestore.
  void _loadNotifications() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _notifications.bindStream(_firestoreService.getNotificationsStream(currentUserId));
    }
  }

  /// Binds the `_users` map to a real-time stream of all users from Firestore.
  /// This is used to display user names and profile pictures in notifications.
  void _loadUsers() {
    _users.bindStream(_firestoreService.getAllUsersStream().map((userList) {
      // Convert the list of users into a map for faster lookup by ID.
      Map<String, UserModel> userMap = {};
      for (var user in userList) {
        userMap[user.id] = user;
      }
      return userMap;
    }));
  }

  /// Retrieves a `UserModel` from the local cache based on their ID.
  UserModel? getUser(String userId) {
    return _users[userId];
  }

  /// Marks a single notification as read in Firestore.
  Future<void> markAsRead(NotificationModel notification) async {
    try {
      // Only perform the update if the notification is not already read.
      if (!notification.isRead) {
        await _firestoreService.markNotificationAsRead(notification.id);
      }
    } catch (e) {
      _error.value = e.toString();
    }
  }

  /// Marks all notifications for the current user as read.
  Future<void> markAllAsRead() async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;
      if (currentUserId != null) {
        await _firestoreService.markAllNotificationsAsRead(currentUserId);
        Get.snackbar('Success', 'All notifications marked as read');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to mark all as read: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Deletes a specific notification from Firestore.
  Future<void> deleteNotification(NotificationModel notification) async {
    try {
      await _firestoreService.deleteNotification(notification.id);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to delete notification: ${e.toString()}');
    }
  }

  /// Handles the action to perform when a notification is tapped.
  void handleNotificationTap(NotificationModel notification) {
    // Mark the tapped notification as read immediately.
    markAsRead(notification);

    // Navigate to a different screen based on the notification type.
    switch (notification.type) {
      case NotificationType.friendRequest:
        Get.toNamed(AppRoutes.friendRequests);
        break;
      case NotificationType.friendRequestAccepted:
      case NotificationType.friendRequestDeclined:
      // These types of notifications lead the user to their friends list.
        Get.toNamed(AppRoutes.friends);
        break;
      case NotificationType.newMessage:
      // For new messages, navigate to the specific chat.
        final userId = notification.data['userId'];
        if (userId != null) {
          final user = getUser(userId);
          if (user != null) {
            Get.toNamed(AppRoutes.chat, arguments: {
              'otherUser': user,
            });
          }
        }
        break;
      case NotificationType.friendRemoved:
      // No navigation needed, just mark as read.
        break;
    }
  }

  /// Formats the notification's timestamp into a user-friendly string.
  String getNotificationTimeText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Fallback to a full date for older notifications.
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Provides a Material icon based on the notification type.
  IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendRequestAccepted:
        return Icons.check_circle;
      case NotificationType.friendRequestDeclined:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.friendRemoved:
        return Icons.person_remove;
    }
  }

  /// Provides a color for the notification icon based on the notification type.
  Color getNotificationIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return AppTheme.primaryColor;
      case NotificationType.friendRequestAccepted:
        return AppTheme.successColor;
      case NotificationType.friendRequestDeclined:
        return AppTheme.errorColor;
      case NotificationType.newMessage:
        return AppTheme.secondaryColor;
      case NotificationType.friendRemoved:
        return AppTheme.errorColor;
    }
  }

  /// Gets the total count of unread notifications.
  int getUnreadCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  /// Clears the current error message.
  void clearError() {
    _error.value = '';
  }
}