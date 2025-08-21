/// Defines the types of messages that can be sent.
enum MessageType {
  /// Represents a standard text message.
  text
}

/// A model class to represent a single chat message.
class MessageModel {
  /// The unique identifier for the message.
  final String id;

  /// The ID of the user who sent the message.
  final String senderId;

  /// The ID of the user who is the intended recipient of the message.
  final String receiverId;

  /// The actual content of the message.
  final String content;

  /// The type of the message, e.g., text, image, video.
  final MessageType type;

  /// The timestamp when the message was sent.
  final DateTime timestamp;

  /// A boolean indicating whether the message has been read by the receiver.
  final bool isRead;

  /// A boolean indicating whether the message has been edited.
  final bool isEdited;

  /// The timestamp when the message was last edited.
  final DateTime? editedAt;

  /// A boolean indicating whether the message has been deleted.
  final bool isDeleted;

  /// The timestamp when the message was deleted.
  final DateTime? deletedAt;

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
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'isEdited': isEdited,
      'editedAt': editedAt?.millisecondsSinceEpoch,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }

  /// Creates a [MessageModel] instance from a map, typically for retrieving data from a database.
  static MessageModel fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isRead: map['isRead'] ?? false,
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'])
          : null,
      isDeleted: map['isDeleted'] ?? false,
      deletedAt: map['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deletedAt'])
          : null,
    );
  }

  /// Creates a new [MessageModel] instance by copying the existing one and optionally updating some fields.
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