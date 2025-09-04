/// An enumeration of the different types of notifications.
///
/// Each notification type corresponds to a specific user action or event
/// in the application that requires user attention. These types help
/// determine notification handling, routing, and display formatting.
enum NotificationType {
  /// A notification for a new friend request.
  /// Triggered when another user sends a friend request to the recipient.
  friendRequest,

  /// A notification that a friend request has been accepted.
  /// Sent to the original requester when their friend request is approved.
  friendRequestAccepted,

  /// A notification that a friend request has been declined.
  /// Sent to the original requester when their friend request is rejected.
  friendRequestDeclined,

  /// A notification for a new message in a chat.
  /// Triggered when a user receives a new message in any conversation.
  newMessage,

  /// A notification indicating a friend has been removed.
  /// Sent when someone removes the user from their friend list.
  friendRemoved
}

/// A model class representing a user notification.
///
/// This model handles in-app notifications that inform users about various
/// events and activities. Notifications can contain additional contextual data
/// and track their read status for proper notification management.
///
/// The model supports different notification types through the [NotificationType]
/// enum and can carry additional payload data for deep linking and contextual actions.
///
/// Example usage:
/// ```dart
/// final notification = NotificationModel(
///   id: 'notif_123',
///   userId: 'user_abc',
///   title: 'New Friend Request',
///   body: 'John Doe wants to be your friend',
///   type: NotificationType.friendRequest,
///   data: {'senderId': 'user_xyz', 'senderName': 'John Doe'},
///   createdAt: DateTime.now(),
/// );
/// ```
class NotificationModel {
  /// The unique identifier for the notification.
  /// Should be generated when creating a new notification (e.g., using UUID).
  /// Used for tracking, updating, and deleting specific notifications.
  final String id;

  /// The ID of the user who is to receive the notification.
  /// References a user in the users collection/table.
  /// Used to filter and display notifications for the correct user.
  final String userId;

  /// The title of the notification.
  /// This is typically displayed as the headline in notification UI.
  /// Should be concise and clearly indicate the notification purpose.
  final String title;

  /// The body text of the notification.
  /// Provides additional details about the notification event.
  /// This is usually displayed as secondary text below the title.
  final String body;

  /// The type of the notification, defined by the [NotificationType] enum.
  /// Determines the notification's icon, color scheme, and tap action.
  /// Used for filtering notifications by type and handling navigation.
  final NotificationType type;

  /// A map containing additional data relevant to the notification, such as sender ID or chat ID.
  ///
  /// Common data fields by notification type:
  /// - friendRequest: {'senderId', 'senderName', 'senderAvatar'}
  /// - friendRequestAccepted: {'accepterId', 'accepterName'}
  /// - newMessage: {'chatId', 'messageId', 'senderId', 'senderName'}
  /// - friendRemoved: {'removerId', 'removerName'}
  ///
  /// This data is used for deep linking when the notification is tapped
  /// and for displaying rich notification content.
  final Map<String, dynamic> data;

  /// A boolean indicating whether the notification has been read by the user.
  /// Used to show unread notification badges and highlight new notifications.
  /// Should be updated to true when the user views or interacts with the notification.
  final bool isRead;

  /// The timestamp when the notification was created.
  /// Used for sorting notifications chronologically and implementing
  /// features like "clear old notifications" or notification expiry.
  final DateTime createdAt;

  /// Creates a new instance of [NotificationModel].
  ///
  /// Required parameters:
  /// - [id]: Unique identifier for the notification
  /// - [userId]: ID of the notification recipient
  /// - [title]: Notification headline text
  /// - [body]: Detailed notification message
  /// - [type]: The type of notification from [NotificationType]
  /// - [createdAt]: When the notification was created
  ///
  /// Optional parameters with defaults:
  /// - [data]: Additional payload data, defaults to empty map
  /// - [isRead]: Read status, defaults to false (unread)
  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {}, // Const for performance optimization
    this.isRead = false,
    required this.createdAt,
  });

  /// Converts a [NotificationModel] instance into a map, suitable for database operations.
  ///
  /// Serializes the notification data for storage in databases like Firestore,
  /// SQLite, or for transmission via push notification services and APIs.
  ///
  /// The enum type is stored as a string for database readability and querying.
  /// DateTime is converted to milliseconds since epoch for consistent storage.
  ///
  /// Returns a Map<String, dynamic> that can be directly stored in most databases.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name, // Converts enum to string for storage
      'data': data, // Map is already in the correct format
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch, // Convert to int for storage
    };
  }

  /// Creates a [NotificationModel] instance from a map, typically for retrieving data from a database.
  ///
  /// This factory constructor deserializes notification data from database queries,
  /// API responses, or push notification payloads. It includes defensive programming
  /// to handle potentially incomplete or corrupted data.
  ///
  /// Parameters:
  /// - [map]: A Map containing the notification data from a database or API
  ///
  /// Returns a new [NotificationModel] instance with data reconstructed from the map.
  ///
  /// Note:
  /// - Safely handles missing or invalid enum values by defaulting to newMessage
  /// - Creates a new Map instance for data to ensure immutability
  /// - Provides sensible defaults for all fields to prevent crashes
  static NotificationModel fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      // Provide default empty strings for required fields if missing
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      // Safely parse notification type, defaulting to newMessage if invalid
      type: NotificationType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => NotificationType.newMessage, // Safe fallback
      ),
      // Create a new Map instance to ensure immutability and handle null case
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      // Default to unread if not specified
      isRead: map['isRead'] ?? false,
      // Convert from milliseconds, defaulting to epoch if missing
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  /// Creates a new [NotificationModel] instance by copying the existing one and optionally updating some fields.
  ///
  /// Implements the immutable update pattern required for state management
  /// solutions like BLoC, Provider, or Riverpod. This ensures that state
  /// changes are trackable and UI updates are triggered properly.
  ///
  /// Common use cases:
  /// - Marking as read: `notification.copyWith(isRead: true)`
  /// - Updating data: `notification.copyWith(data: updatedData)`
  /// - Batch updates: `notification.copyWith(isRead: true, data: newData)`
  ///
  /// All parameters are optional. Unprovided parameters retain their current values.
  ///
  /// Example:
  /// ```dart
  /// // Mark notification as read
  /// final readNotification = notification.copyWith(isRead: true);
  ///
  /// // Update notification with additional data
  /// final updatedNotification = notification.copyWith(
  ///   data: {...notification.data, 'viewedAt': DateTime.now().toIso8601String()},
  /// );
  /// ```
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      // Use provided value if not null, otherwise keep current value
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
