/// Enum representing the possible states of a friend request
enum FriendRequestStatus { pending, accepted, declined }

/// Model class for managing friend requests between users
/// Contains all necessary information about a friend request including
/// sender, receiver, status, and timestamps
class FriendRequestModel {
  /// Unique identifier for the friend request
  final String id;

  /// ID of the user who sent the friend request
  final String senderId;

  /// ID of the user who received the friend request
  final String receiverId;

  /// Current status of the friend request (pending, accepted, or declined)
  final FriendRequestStatus status;

  /// Timestamp when the friend request was created
  final DateTime createdAt;

  /// Timestamp when the friend request was responded to (accepted/declined)
  /// Null if the request is still pending
  final DateTime? respondedAt;

  /// Optional message attached to the friend request
  final String? message;

  /// Constructor for creating a new FriendRequestModel instance
  /// [id], [senderId], [receiverId], and [createdAt] are required
  /// [status] defaults to pending if not specified
  /// [respondedAt] and [message] are optional
  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  /// Converts the FriendRequestModel instance to a Map for database storage or API calls
  /// DateTime objects are converted to milliseconds since epoch for serialization
  /// Status enum is converted to its string name
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
      'message': message,
    };
  }

  /// Creates a FriendRequestModel instance from a Map (typically from database or API)
  /// Handles null safety by providing default values for missing fields
  /// Converts milliseconds back to DateTime objects
  /// Safely parses status string back to enum, defaults to pending if invalid
  static FriendRequestModel fromMap(Map<String, dynamic> map) {
    return FriendRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      respondedAt: map['respondedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['respondedAt'])
          : null,
      message: map['message'],
    );
  }

  /// Creates a copy of the current instance with optional parameter overrides
  /// Useful for updating specific fields while maintaining immutability
  /// Any parameter not provided will retain its current value
  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? message,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
    );
  }
}
