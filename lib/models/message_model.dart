/// Defines the types of messages that can be sent.
///
/// This enum can be extended in the future to support additional message types
/// like images, videos, voice notes, files, locations, etc.
enum MessageType {
  /// Represents a standard text message.
  text
}

/// A model class to represent a single chat message.
///
/// This model handles the complete lifecycle of a message including creation,
/// reading, editing, and soft deletion. It maintains timestamps for all
/// significant events in the message's lifecycle.
///
/// Example usage:
/// ```dart
/// final message = MessageModel(
///   id: 'msg_123',
///   senderId: 'user_abc',
///   receiverId: 'user_xyz',
///   content: 'Hello, how are you?',
///   timestamp: DateTime.now(),
/// );
/// ```
class MessageModel {
  /// The unique identifier for the message.
  /// This should be generated when creating a new message (e.g., using UUID).
  final String id;

  /// The ID of the user who sent the message.
  /// This references a user in the users collection/table.
  final String senderId;

  /// The ID of the user who is the intended recipient of the message.
  /// Together with senderId, this defines the conversation participants.
  final String receiverId;

  /// The actual content of the message.
  /// For text messages, this contains the message text.
  /// For other types (when implemented), this might contain URLs or metadata.
  final String content;

  /// The type of the message, e.g., text, image, video.
  /// Currently only supports text, but designed to be extensible.
  final MessageType type;

  /// The timestamp when the message was sent.
  /// This is used for ordering messages chronologically in conversations.
  final DateTime timestamp;

  /// A boolean indicating whether the message has been read by the receiver.
  /// Used to show read receipts and unread message counts.
  /// Should be updated when the receiver views the message.
  final bool isRead;

  /// A boolean indicating whether the message has been edited.
  /// When true, UI should show an "edited" indicator near the message.
  final bool isEdited;

  /// The timestamp when the message was last edited.
  /// This is null for messages that have never been edited.
  /// Should be updated each time the message content is modified.
  final DateTime? editedAt;

  /// A boolean indicating whether the message has been deleted.
  /// Implements soft delete - the message still exists in the database
  /// but should be hidden or shown as "deleted" in the UI.
  final bool isDeleted;

  /// The timestamp when the message was deleted.
  /// This is null for messages that haven't been deleted.
  /// Useful for implementing features like "restore deleted messages"
  /// or automatic permanent deletion after a certain period.
  final DateTime? deletedAt;

  /// Creates a new instance of [MessageModel].
  ///
  /// Required parameters:
  /// - [id]: Unique identifier for the message
  /// - [senderId]: ID of the message sender
  /// - [receiverId]: ID of the message recipient
  /// - [content]: The message content
  /// - [timestamp]: When the message was sent
  ///
  /// Optional parameters with defaults:
  /// - [type]: Defaults to MessageType.text
  /// - [isRead]: Defaults to false (unread)
  /// - [isEdited]: Defaults to false (not edited)
  /// - [editedAt]: Null by default (never edited)
  /// - [isDeleted]: Defaults to false (not deleted)
  /// - [deletedAt]: Null by default (never deleted)
  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  /// Converts a [MessageModel] instance into a map, suitable for database operations.
  ///
  /// This method serializes the message data for storage in databases like
  /// Firestore, SQLite, or for transmission via APIs. DateTime objects are
  /// converted to milliseconds since epoch for consistent storage.
  ///
  /// The enum type is stored as a string using the .name property for
  /// readability and database querying.
  ///
  /// Returns a Map<String, dynamic> containing all message data.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name, // Stores enum as string for database readability
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'isEdited': isEdited,
      'editedAt': editedAt?.millisecondsSinceEpoch, // Null-aware operator for optional field
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch, // Null-aware operator for optional field
    };
  }

  /// Creates a [MessageModel] instance from a map, typically for retrieving data from a database.
  ///
  /// This factory constructor deserializes data from database queries or API responses.
  /// It includes defensive programming with null checks and default values to handle
  /// potentially incomplete or corrupted data gracefully.
  ///
  /// Parameters:
  /// - [map]: A Map containing the message data, usually from a database query
  ///
  /// Returns a new [MessageModel] instance reconstructed from the map data.
  ///
  /// Note: The method safely handles missing or invalid enum values by
  /// defaulting to MessageType.text if the stored type is unrecognized.
  static MessageModel fromMap(Map<String, dynamic> map) {
    return MessageModel(
      // Provide default empty strings for required string fields if missing
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      // Safely parse the message type enum from string, defaulting to text if invalid
      type: MessageType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      // Convert timestamp from milliseconds, defaulting to epoch if missing
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      // Boolean fields default to false if missing
      isRead: map['isRead'] ?? false,
      isEdited: map['isEdited'] ?? false,
      // Conditionally create DateTime from milliseconds only if the value exists
      editedAt: map['editedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'])
          : null,
      isDeleted: map['isDeleted'] ?? false,
      // Conditionally create DateTime from milliseconds only if the value exists
      deletedAt: map['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deletedAt'])
          : null,
    );
  }

  /// Creates a new [MessageModel] instance by copying the existing one and optionally updating some fields.
  ///
  /// This implements the immutable update pattern, essential for state management
  /// solutions like BLoC, Provider, or Riverpod. Instead of mutating the existing
  /// instance, it creates a new one with updated values.
  ///
  /// Common use cases:
  /// - Marking a message as read: `message.copyWith(isRead: true)`
  /// - Editing a message: `message.copyWith(content: newContent, isEdited: true, editedAt: DateTime.now())`
  /// - Soft deleting: `message.copyWith(isDeleted: true, deletedAt: DateTime.now())`
  ///
  /// All parameters are optional. If not provided, the current instance's values are retained.
  ///
  /// Example:
  /// ```dart
  /// final readMessage = message.copyWith(isRead: true);
  /// final editedMessage = message.copyWith(
  ///   content: 'Updated content',
  ///   isEdited: true,
  ///   editedAt: DateTime.now(),
  /// );
  /// ```
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return MessageModel(
      // Use provided value if not null, otherwise keep current value
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
