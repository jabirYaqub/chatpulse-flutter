/// Represents the relationship between two users, tracking friendship status and block information.
class FriendshipModel {
  /// Unique identifier for the friendship record.
  final String id;

  /// The ID of the first user in the friendship.
  final String user1Id;

  /// The ID of the second user in the friendship.
  final String user2Id;

  /// The timestamp when the friendship was created.
  final DateTime createdAt;

  /// A boolean indicating whether one of the users has blocked the other.
  final bool isBlocked;

  /// The ID of the user who initiated the block, if any.
  final String? blockedBy;

  FriendshipModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    this.isBlocked = false,
    this.blockedBy,
  });

  /// Converts a [FriendshipModel] instance into a map, typically for storage in a database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isBlocked': isBlocked,
      'blockedBy': blockedBy,
    };
  }

  /// Creates a [FriendshipModel] instance from a map, typically for retrieving data from a database.
  static FriendshipModel fromMap(Map<String, dynamic> map) {
    return FriendshipModel(
      id: map['id'] ?? '',
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isBlocked: map['isBlocked'] ?? false,
      blockedBy: map['blockedBy'],
    );
  }

  /// Creates a new [FriendshipModel] instance by copying the existing one and optionally updating some fields.
  FriendshipModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    DateTime? createdAt,
    bool? isBlocked,
    String? blockedBy,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      createdAt: createdAt ?? this.createdAt,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedBy: blockedBy ?? this.blockedBy,
    );
  }

  /// Gets the ID of the other user in the friendship based on the current user's ID.
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  /// Checks if the current user has been blocked by the specified user.
  bool isBlockedBy(String userId) {
    return isBlocked && blockedBy == userId;
  }
}