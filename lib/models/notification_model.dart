/// An enumeration of the different types of notifications.
enum NotificationType {
  /// A notification for a new friend request.
  friendRequest,

  /// A notification that a friend request has been accepted.
  friendRequestAccepted,

  /// A notification that a friend request has been declined.
  friendRequestDeclined,

  /// A notification for a new message in a chat.
  newMessage,

  /// A notification indicating a friend has been removed.
  friendRemoved
}

/// A model class representing a user notification.
class NotificationModel {
  /// The unique identifier for the notification.
  final String id;

  /// The ID of the user who is to receive the notification.
  final String userId;

  /// The title of the notification.
  final String title;

  /// The body text of the notification.
  final String body;

  /// The type of the notification, defined by the [NotificationType] enum.
  final NotificationType type;

  /// A map containing additional data relevant to the notification, such as sender ID or chat ID.
  final Map<String, dynamic> data;

  /// A boolean indicating whether the notification has been read by the user.
  final bool isRead;

  /// The timestamp when the notification was created.
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  /// Converts a [NotificationModel] instance into a map, suitable for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a [NotificationModel] instance from a map, typically for retrieving data from a database.
  static NotificationModel fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => NotificationType.newMessage,
      ),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['isRead'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  /// Creates a new [NotificationModel] instance by copying the existing one and optionally updating some fields.
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