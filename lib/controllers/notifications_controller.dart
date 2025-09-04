import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/models/notification_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

/// NotificationsController manages all logic related to the user's notifications.
/// It handles fetching notifications, marking them as read, and navigating
/// the user to the appropriate screen when a notification is tapped.
///
/// This controller is responsible for:
/// - Real-time streaming of user notifications from Firestore
/// - User data caching for displaying notification sender information
/// - Individual and bulk notification read status management
/// - Type-specific navigation when notifications are tapped
/// - Notification deletion and cleanup operations
/// - UI formatting for timestamps, icons, and colors
/// - Integration with app theme for consistent styling
/// - Error handling and user feedback for all operations
class NotificationsController extends GetxController {

  // ==================== DEPENDENCIES ====================

  /// Dependencies are injected for a clean, modular design.
  /// These provide data access and authentication functionality.

  /// Service for Firestore database operations (notifications, users)
  final FirestoreService _firestoreService = FirestoreService();

  /// Authentication controller to access current user information
  final AuthController _authController = Get.find<AuthController>();

  // ==================== REACTIVE STATE VARIABLES ====================

  /// Reactive state variables to manage the UI using GetX observables.
  /// These automatically update the UI when values change.

  /// A stream of notifications for the user from Firestore
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;

  /// A cache of all users for easy lookup when displaying notification details
  /// Structure: {userId: UserModel} for efficient O(1) profile access
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;

  /// Tracks global loading state for bulk operations like mark all as read
  final RxBool _isLoading = false.obs;

  /// Stores any error messages that occur during operations
  final RxString _error = ''.obs;

  // ==================== PUBLIC GETTERS ====================

  /// Public getters to provide read-only access to the reactive state.
  /// These expose current state without allowing external modification.

  /// Returns the list of user's notifications
  List<NotificationModel> get notifications => _notifications;

  /// Returns the cached user data map for profile information
  Map<String, UserModel> get users => _users;

  /// Returns true if any bulk operation is in progress
  bool get isLoading => _isLoading.value;

  /// Returns current error message or empty string if no error
  String get error => _error.value;

  // ==================== LIFECYCLE METHODS ====================

  /// Called automatically by GetX when the controller is first created.
  /// Sets up real-time data streams for notifications and user data.
  @override
  void onInit() {
    super.onInit();
    // Start listening to data streams for real-time updates.
    _loadNotifications();
    _loadUsers();
  }

  // ==================== DATA LOADING AND STREAMING ====================

  /// Binds the `_notifications` list to a real-time stream from Firestore.
  /// This provides automatic updates when new notifications arrive or are modified.
  void _loadNotifications() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      // Create reactive binding to Firestore notifications stream
      _notifications.bindStream(_firestoreService.getNotificationsStream(currentUserId));
    }
  }

  /// Binds the `_users` map to a real-time stream of all users from Firestore.
  /// This is used to display user names and profile pictures in notifications
  /// without making individual database calls for each notification.
  void _loadUsers() {
    // Transform user list stream into map for efficient lookups
    _users.bindStream(_firestoreService.getAllUsersStream().map((userList) {
      // Convert the list of users into a map for faster lookup by ID.
      // This eliminates the need for linear searches when displaying notification details.
      Map<String, UserModel> userMap = {};
      for (var user in userList) {
        userMap[user.id] = user;
      }
      return userMap;
    }));
  }

  // ==================== USER DATA ACCESS ====================

  /// Retrieves a `UserModel` from the local cache based on their ID.
  /// This provides efficient access to user profile information for notifications
  /// without making database calls. Returns null if user not found in cache.
  UserModel? getUser(String userId) {
    return _users[userId];
  }

  // ==================== NOTIFICATION READ STATUS MANAGEMENT ====================

  /// Marks a single notification as read in Firestore.
  /// This updates both the database and triggers UI updates through the stream.
  Future<void> markAsRead(NotificationModel notification) async {
    try {
      // Only perform the update if the notification is not already read.
      // This prevents unnecessary database writes and optimizes performance.
      if (!notification.isRead) {
        await _firestoreService.markNotificationAsRead(notification.id);
      }
    } catch (e) {
      // Store error for potential UI display
      _error.value = e.toString();
    }
  }

  /// Marks all notifications for the current user as read.
  /// This is a bulk operation useful for "mark all as read" functionality.
  Future<void> markAllAsRead() async {
    try {
      // Set loading state to show progress indicators
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;
      if (currentUserId != null) {
        // Perform bulk read operation in Firestore
        await _firestoreService.markAllNotificationsAsRead(currentUserId);
        // Show success feedback to user
        Get.snackbar('Success', 'All notifications marked as read');
      }
    } catch (e) {
      // Handle bulk operation errors
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to mark all as read: ${e.toString()}');
    } finally {
      // Always reset loading state
      _isLoading.value = false;
    }
  }

  // ==================== NOTIFICATION DELETION ====================

  /// Deletes a specific notification from Firestore.
  /// This permanently removes the notification from the user's list.
  Future<void> deleteNotification(NotificationModel notification) async {
    try {
      // Remove notification from database
      await _firestoreService.deleteNotification(notification.id);
    } catch (e) {
      // Handle deletion errors with user feedback
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to delete notification: ${e.toString()}');
    }
  }

  // ==================== NOTIFICATION INTERACTION HANDLING ====================

  /// Handles the action to perform when a notification is tapped.
  /// This provides type-specific navigation and automatically marks notifications as read.
  void handleNotificationTap(NotificationModel notification) {
    // Mark the tapped notification as read immediately for better UX.
    // This provides instant visual feedback even before database update completes.
    markAsRead(notification);

    // Navigate to a different screen based on the notification type.
    // Each notification type has specific navigation logic based on its purpose.
    switch (notification.type) {
      case NotificationType.friendRequest:
      // Friend request notifications take user to friend requests screen
        Get.toNamed(AppRoutes.friendRequests);
        break;
      case NotificationType.friendRequestAccepted:
      case NotificationType.friendRequestDeclined:
      // These types of notifications lead the user to their friends list.
      // User can see the updated friendship status there.
        Get.toNamed(AppRoutes.friends);
        break;
      case NotificationType.newMessage:
      // For new messages, navigate to the specific chat with the sender.
        final userId = notification.data['userId'];
        if (userId != null) {
          final user = getUser(userId);
          if (user != null) {
            // Navigate to chat screen with the message sender
            Get.toNamed(AppRoutes.chat, arguments: {
              'otherUser': user,
            });
          }
        }
        break;
      case NotificationType.friendRemoved:
      // No navigation needed for friend removal notifications, just mark as read.
      // The notification itself provides sufficient information.
        break;
    }
  }

  // ==================== FORMATTING AND UI UTILITIES ====================

  /// Formats the notification's timestamp into a user-friendly string.
  /// This provides intuitive time representations for when notifications were created.
  String getNotificationTimeText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      // Very recent notifications
      return 'Just now';
    } else if (difference.inHours < 1) {
      // Notifications within the hour
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      // Notifications from today
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      // Notifications from this week
      return '${difference.inDays}d ago';
    } else {
      // Fallback to a full date for older notifications.
      // This provides clear dates for notifications older than a week.
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Provides a Material icon based on the notification type.
  /// This creates consistent visual representation for different notification types.
  IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
      // Person add icon for incoming friend requests
        return Icons.person_add;
      case NotificationType.friendRequestAccepted:
      // Check circle for accepted friend requests (positive outcome)
        return Icons.check_circle;
      case NotificationType.friendRequestDeclined:
      // Cancel icon for declined friend requests (negative outcome)
        return Icons.cancel;
      case NotificationType.newMessage:
      // Message icon for chat notifications
        return Icons.message;
      case NotificationType.friendRemoved:
      // Person remove icon for friendship terminations
        return Icons.person_remove;
    }
  }

  /// Provides a color for the notification icon based on the notification type.
  /// This enables visual categorization using the app's theme colors.
  Color getNotificationIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
      // Primary color for friend requests (neutral action)
        return AppTheme.primaryColor;
      case NotificationType.friendRequestAccepted:
      // Success color for positive outcomes
        return AppTheme.successColor;
      case NotificationType.friendRequestDeclined:
      // Error color for negative outcomes
        return AppTheme.errorColor;
      case NotificationType.newMessage:
      // Secondary color for message notifications
        return AppTheme.secondaryColor;
      case NotificationType.friendRemoved:
      // Error color for friend removal (negative action)
        return AppTheme.errorColor;
    }
  }

  // ==================== COUNT AND STATUS METHODS ====================

  /// Gets the total count of unread notifications.
  /// This is used for badge display in the UI to show unread notification count.
  int getUnreadCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  // ==================== UTILITY METHODS ====================

  /// Clears the current error message.
  /// Useful for resetting error state when user dismisses errors
  /// or when starting new operations that should have clean error state.
  void clearError() {
    _error.value = '';
  }
}
