/// Represents the relationship between two users, tracking friendship status and block information.
///
/// This model is designed to handle bidirectional friendships where the order of user IDs
/// doesn't matter for the friendship itself, but blocking functionality is unidirectional.
///
/// Example usage:
/// ```dart
/// final friendship = FriendshipModel(
///   id: 'friendship_123',
///   user1Id: 'user_abc',
///   user2Id: 'user_xyz',
///   createdAt: DateTime.now(),
/// );
/// ```
class FriendshipModel {
  /// Unique identifier for the friendship record.
  /// This should be generated when creating a new friendship (e.g., using UUID).
  final String id;

  /// The ID of the first user in the friendship.
  /// Note: The order of user1Id and user2Id doesn't imply any hierarchy;
  /// both users are equal participants in the friendship.
  final String user1Id;

  /// The ID of the second user in the friendship.
  /// Together with user1Id, this forms a unique friendship pair.
  final String user2Id;

  /// The timestamp when the friendship was created.
  /// This helps track the duration of friendships and can be used
  /// for sorting friendships by recency.
  final DateTime createdAt;

  /// A boolean indicating whether one of the users has blocked the other.
  /// When true, the friendship is effectively suspended and users
  /// should not be able to interact through the app.
  final bool isBlocked;

  /// The ID of the user who initiated the block, if any.
  /// This field is null when isBlocked is false.
  /// Only the user who blocked can unblock the friendship.
  final String? blockedBy;

  /// Creates a new instance of [FriendshipModel].
  ///
  /// Required parameters:
  /// - [id]: Unique identifier for this friendship
  /// - [user1Id]: ID of the first user
  /// - [user2Id]: ID of the second user
  /// - [createdAt]: When the friendship was established
  ///
  /// Optional parameters:
  /// - [isBlocked]: Defaults to false (unblocked friendship)
  /// - [blockedBy]: Should be provided when isBlocked is true
  FriendshipModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    this.isBlocked = false,
    this.blockedBy,
  });

  /// Converts a [FriendshipModel] instance into a map, typically for storage in a database.
  ///
  /// The returned map structure is compatible with common database formats like
  /// Firestore or SQLite. The createdAt DateTime is converted to milliseconds
  /// since epoch for consistent storage across platforms.
  ///
  /// Returns a Map<String, dynamic> containing all friendship data.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'createdAt': createdAt.millisecondsSinceEpoch, // Store as int for database compatibility
      'isBlocked': isBlocked,
      'blockedBy': blockedBy, // Will be null if no block exists
    };
  }

  /// Creates a [FriendshipModel] instance from a map, typically for retrieving data from a database.
  ///
  /// This factory constructor handles potential null or missing values gracefully
  /// by providing default values. This ensures the app doesn't crash when dealing
  /// with incomplete or corrupted data from the database.
  ///
  /// Parameters:
  /// - [map]: A Map containing the friendship data, usually from a database query
  ///
  /// Returns a new [FriendshipModel] instance with the data from the map.
  static FriendshipModel fromMap(Map<String, dynamic> map) {
    return FriendshipModel(
      // Default to empty string if ID is missing (consider validation in production)
      id: map['id'] ?? '',
      // Default to empty strings for user IDs if missing
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      // Convert milliseconds back to DateTime, defaulting to epoch if missing
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      // Default to false (unblocked) if not specified
      isBlocked: map['isBlocked'] ?? false,
      // Can be null, which is the expected state for unblocked friendships
      blockedBy: map['blockedBy'],
    );
  }

  /// Creates a new [FriendshipModel] instance by copying the existing one and optionally updating some fields.
  ///
  /// This method implements the immutable update pattern, which is essential for
  /// state management solutions like BLoC or Provider. Instead of modifying the
  /// existing instance, it creates a new one with updated values.
  ///
  /// All parameters are optional. If not provided, the current instance's values are used.
  ///
  /// Example:
  /// ```dart
  /// final blockedFriendship = friendship.copyWith(
  ///   isBlocked: true,
  ///   blockedBy: 'user_abc',
  /// );
  /// ```
  FriendshipModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    DateTime? createdAt,
    bool? isBlocked,
    String? blockedBy,
  }) {
    return FriendshipModel(
      // Use provided value if not null, otherwise keep current value
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      createdAt: createdAt ?? this.createdAt,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedBy: blockedBy ?? this.blockedBy,
    );
  }

  /// Gets the ID of the other user in the friendship based on the current user's ID.
  ///
  /// This utility method is useful when displaying a user's friend list,
  /// where you need to show information about the other person in each friendship.
  ///
  /// Parameters:
  /// - [currentUserId]: The ID of the user whose perspective we're considering
  ///
  /// Returns the ID of the other user in this friendship.
  /// If currentUserId matches neither user1Id nor user2Id, it returns user1Id.
  ///
  /// Example:
  /// ```dart
  /// final friendId = friendship.getOtherUserId('user_abc');
  /// // Returns 'user_xyz' if user_abc is user1Id
  /// ```
  String getOtherUserId(String currentUserId) {
    // If current user is user1, return user2; otherwise return user1
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  /// Checks if the current user has been blocked by the specified user.
  ///
  /// This method helps determine if a specific user initiated the block,
  /// which is important for UI logic (e.g., showing "You blocked this user"
  /// vs "This user blocked you").
  ///
  /// Parameters:
  /// - [userId]: The ID of the user to check if they initiated the block
  ///
  /// Returns true only if:
  /// 1. The friendship is currently blocked (isBlocked == true)
  /// 2. The specified user is the one who initiated the block (blockedBy == userId)
  ///
  /// Example:
  /// ```dart
  /// if (friendship.isBlockedBy('user_abc')) {
  ///   print('User ABC has blocked this friendship');
  /// }
  /// ```
  bool isBlockedBy(String userId) {
    // Both conditions must be true: friendship is blocked AND this user blocked it
    return isBlocked && blockedBy == userId;
  }
}
