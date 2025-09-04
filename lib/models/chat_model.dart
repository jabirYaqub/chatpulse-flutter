/// ChatModel represents a chat conversation between users in the messaging system.
/// This model handles all aspects of chat data including participant management,
/// message tracking, read status, deletion states, and serialization for database storage.
///
/// The model supports:
/// - Two-person chat conversations with participant tracking
/// - Last message caching for efficient chat list display
/// - Per-user unread message counting for notification badges
/// - Soft deletion system allowing users to hide chats without affecting others
/// - Read receipt functionality with last seen timestamps
/// - Database serialization/deserialization for Firestore storage
/// - Immutable updates through copyWith pattern
class ChatModel {
  // ==================== CORE CHAT IDENTIFICATION ====================

  /// Unique identifier for the chat.
  /// This ID is used to reference the chat across the entire application
  /// and serves as the document ID in Firestore.
  final String id;

  /// List of user IDs participating in the chat.
  /// Currently supports two-person chats, but designed to be extensible
  /// for group chats in the future.
  final List<String> participants;

  // ==================== LAST MESSAGE CACHING ====================

  /// The content of the last message in the chat.
  /// This is cached here for efficient display in chat lists without
  /// needing to query the messages subcollection.
  final String? lastMessage;

  /// The timestamp of the last message.
  /// Used for sorting chats by recency and determining message age.
  final DateTime? lastMessageTime;

  /// The ID of the user who sent the last message.
  /// Used for determining message direction and read status calculations.
  final String? lastMessageSenderId;

  // ==================== READ STATUS AND NOTIFICATIONS ====================

  /// A map storing the number of unread messages for each participant.
  /// Structure: {userId: unreadCount}
  /// This enables per-user notification badges and read status tracking.
  final Map<String, int> unreadCount;

  // ==================== SOFT DELETION SYSTEM ====================

  /// A map to track which users have deleted the chat from their view.
  /// Structure: {userId: isDeleted}
  /// This implements soft deletion where users can hide chats without
  /// affecting other participants' ability to see the conversation.
  final Map<String, bool> deletedBy;

  /// A map to track the timestamp of when each user deleted the chat.
  /// Structure: {userId: deletionTimestamp}
  /// This allows for potential chat recovery functionality and audit trails.
  final Map<String, DateTime?> deletedAt;

  // ==================== READ RECEIPTS AND ACTIVITY TRACKING ====================

  /// A map to track the last seen timestamp for each participant.
  /// Structure: {userId: lastSeenTimestamp}
  /// This enables read receipts and "last seen" functionality for messages.
  final Map<String, DateTime?> lastSeenBy;

  // ==================== METADATA TIMESTAMPS ====================

  /// The timestamp when the chat was created.
  /// Used for sorting, analytics, and determining chat age.
  final DateTime createdAt;

  /// The timestamp when the chat was last updated.
  /// Updated whenever messages are sent, read status changes, etc.
  /// Used for change tracking and synchronization.
  final DateTime updatedAt;

  // ==================== CONSTRUCTOR ====================

  /// Creates a new ChatModel instance with required and optional parameters.
  /// Uses const empty maps as defaults for optional tracking maps to avoid null issues.
  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    this.deletedBy = const {},           // Default to empty - no users have deleted
    this.deletedAt = const {},           // Default to empty - no deletion timestamps
    this.lastSeenBy = const {},          // Default to empty - no last seen data yet
    required this.createdAt,
    required this.updatedAt,
  });

  // ==================== DATABASE SERIALIZATION ====================

  /// Converts a [ChatModel] instance into a map for database storage.
  /// This is useful for saving data to a database like Firestore.
  ///
  /// Handles DateTime conversion to milliseconds since epoch for JSON compatibility.
  /// Nested maps with DateTime values are converted recursively.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      // Convert DateTime to milliseconds for JSON serialization
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'deletedBy': deletedBy,
      // Convert nested DateTime values to milliseconds
      'deletedAt': deletedAt.map((key, value) => MapEntry(key, value?.millisecondsSinceEpoch)),
      'lastSeenBy': lastSeenBy.map((key, value) => MapEntry(key, value?.millisecondsSinceEpoch)),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a [ChatModel] instance from a map retrieved from database.
  /// This is used to retrieve data from a database and convert it into a model.
  ///
  /// Includes comprehensive null safety and type conversion handling.
  /// Reconstructs DateTime objects from millisecond timestamps.
  static ChatModel fromMap(Map<String, dynamic> map) {
    // Reconstruct lastSeenBy map with proper DateTime conversion
    Map<String, DateTime?> lastSeenMap = {};
    if (map['lastSeenBy'] != null) {
      Map<String, dynamic> rawLastSeen = Map<String, dynamic>.from(map['lastSeenBy']);
      // Convert each timestamp back to DateTime, handling null values
      lastSeenMap = rawLastSeen.map((key, value) =>
          MapEntry(key, value != null ? DateTime.fromMillisecondsSinceEpoch(value) : null));
    }

    // Reconstruct deletedAt map with proper DateTime conversion
    Map<String, DateTime?> deletedAtMap = {};
    if (map['deletedAt'] != null) {
      Map<String, dynamic> rawDeletedAt = Map<String, dynamic>.from(map['deletedAt']);
      // Convert each timestamp back to DateTime, handling null values
      deletedAtMap = rawDeletedAt.map((key, value) =>
          MapEntry(key, value != null ? DateTime.fromMillisecondsSinceEpoch(value) : null));
    }

    return ChatModel(
      id: map['id'] ?? '',    // Provide empty string fallback
      participants: List<String>.from(map['participants'] ?? []),  // Handle null with empty list
      lastMessage: map['lastMessage'],  // Can be null
      // Convert timestamp back to DateTime if present
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],  // Can be null
      // Ensure proper type conversion for unread count map
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      // Ensure proper type conversion for deletion status map
      deletedBy: Map<String, bool>.from(map['deletedBy'] ?? {}),
      deletedAt: deletedAtMap,
      lastSeenBy: lastSeenMap,
      // Handle potential null timestamps with epoch fallback
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  // ==================== IMMUTABLE UPDATES ====================

  /// Creates a copy of the current [ChatModel] instance with updated values.
  /// This is useful for updating specific properties without re-creating the entire object.
  ///
  /// Follows the copyWith pattern for immutable data structures, allowing selective
  /// property updates while maintaining immutability and type safety.
  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    Map<String, bool>? deletedBy,
    Map<String, DateTime?>? deletedAt,
    Map<String, DateTime?>? lastSeenBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      // Use provided value or fallback to current value
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSeenBy: lastSeenBy ?? this.lastSeenBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ==================== UTILITY METHODS FOR CHAT OPERATIONS ====================

  /// Gets the ID of the other participant in a two-person chat.
  /// This is essential for determining who the current user is chatting with.
  /// Returns an empty string if not found (error case).
  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
          (id) => id != currentUserId,  // Find participant who isn't current user
      orElse: () => '',               // Return empty string if not found
    );
  }

  /// Gets the number of unread messages for a specific user.
  /// This is used for displaying notification badges in the UI.
  /// Returns 0 if user has no unread messages or isn't in the map.
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Checks if the chat has been deleted by a specific user.
  /// This implements the soft deletion system where users can hide chats.
  /// Returns false if user hasn't deleted the chat or isn't in the map.
  bool isDeletedBy(String userId) {
    return deletedBy[userId] ?? false;
  }

  /// Gets the timestamp when a specific user deleted the chat.
  /// This can be used for audit trails or potential recovery functionality.
  /// Returns null if user hasn't deleted the chat or deletion time wasn't recorded.
  DateTime? getDeletedAt(String userId) {
    return deletedAt[userId];
  }

  /// Gets the last seen timestamp for a specific user.
  /// This is used for read receipts and "last active" indicators.
  /// Returns null if user hasn't been seen or timestamp wasn't recorded.
  DateTime? getLastSeenBy(String userId) {
    return lastSeenBy[userId];
  }

  // ==================== READ RECEIPT FUNCTIONALITY ====================

  /// Checks if the last message sent by the [currentUserId] has been seen by the [otherUserId].
  /// This implements read receipts by comparing last seen timestamps with message timestamps.
  ///
  /// Returns true only if:
  /// 1. The last message was sent by the current user
  /// 2. The other user has a recorded last seen time
  /// 3. The other user's last seen time is after or at the message time
  bool isMessageSeen(String currentUserId, String otherUserId) {
    // Check if the last message was sent by the current user
    // Only check read status for messages sent by current user
    if (lastMessageSenderId == currentUserId) {
      final otherUserLastSeen = getLastSeenBy(otherUserId);
      // Ensure the other user's last seen time is not null and is after or at the same moment as the last message time
      if (otherUserLastSeen != null && lastMessageTime != null) {
        // Message is seen if other user's last seen time is after the message time
        // or at exactly the same moment (handles edge cases with precise timing)
        return otherUserLastSeen.isAfter(lastMessageTime!) ||
            otherUserLastSeen.isAtSameMomentAs(lastMessageTime!);
      }
    }
    // Return false if conditions aren't met (message not by current user,
    // no last seen data, or user hasn't seen the message yet)
    return false;
  }
}
