class ChatModel {
  /// Unique identifier for the chat.
  final String id;

  /// List of user IDs participating in the chat.
  final List<String> participants;

  /// The content of the last message in the chat.
  final String? lastMessage;

  /// The timestamp of the last message.
  final DateTime? lastMessageTime;

  /// The ID of the user who sent the last message.
  final String? lastMessageSenderId;

  /// A map storing the number of unread messages for each participant.
  final Map<String, int> unreadCount;

  /// A map to track which users have deleted the chat from their view.
  final Map<String, bool> deletedBy;

  /// A map to track the timestamp of when each user deleted the chat.
  final Map<String, DateTime?> deletedAt;

  /// A map to track the last seen timestamp for each participant.
  final Map<String, DateTime?> lastSeenBy;

  /// The timestamp when the chat was created.
  final DateTime createdAt;

  /// The timestamp when the chat was last updated.
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    this.deletedBy = const {},
    this.deletedAt = const {},
    this.lastSeenBy = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converts a [ChatModel] instance into a map.
  /// This is useful for saving data to a database like Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'deletedBy': deletedBy,
      'deletedAt': deletedAt.map((key, value) => MapEntry(key, value?.millisecondsSinceEpoch)),
      'lastSeenBy': lastSeenBy.map((key, value) => MapEntry(key, value?.millisecondsSinceEpoch)),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a [ChatModel] instance from a map.
  /// This is used to retrieve data from a database and convert it into a model.
  static ChatModel fromMap(Map<String, dynamic> map) {
    Map<String, DateTime?> lastSeenMap = {};
    if (map['lastSeenBy'] != null) {
      Map<String, dynamic> rawLastSeen = Map<String, dynamic>.from(map['lastSeenBy']);
      lastSeenMap = rawLastSeen.map((key, value) =>
          MapEntry(key, value != null ? DateTime.fromMillisecondsSinceEpoch(value) : null));
    }

    Map<String, DateTime?> deletedAtMap = {};
    if (map['deletedAt'] != null) {
      Map<String, dynamic> rawDeletedAt = Map<String, dynamic>.from(map['deletedAt']);
      deletedAtMap = rawDeletedAt.map((key, value) =>
          MapEntry(key, value != null ? DateTime.fromMillisecondsSinceEpoch(value) : null));
    }

    return ChatModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      deletedBy: Map<String, bool>.from(map['deletedBy'] ?? {}),
      deletedAt: deletedAtMap,
      lastSeenBy: lastSeenMap,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  /// Creates a copy of the current [ChatModel] instance with updated values.
  /// This is useful for updating specific properties without re-creating the entire object.
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

  /// Gets the ID of the other participant in a two-person chat.
  /// Returns an empty string if not found.
  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Gets the number of unread messages for a specific user.
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Checks if the chat has been deleted by a specific user.
  bool isDeletedBy(String userId) {
    return deletedBy[userId] ?? false;
  }

  /// Gets the timestamp when a specific user deleted the chat.
  DateTime? getDeletedAt(String userId) {
    return deletedAt[userId];
  }

  /// Gets the last seen timestamp for a specific user.
  DateTime? getLastSeenBy(String userId) {
    return lastSeenBy[userId];
  }

  ///Checks if the last message sent by the [currentUserId] has been seen by the [otherUserId].
  bool isMessageSeen(String currentUserId, String otherUserId) {
    // Check if the last message was sent by the current user
    if (lastMessageSenderId == currentUserId) {
      final otherUserLastSeen = getLastSeenBy(otherUserId);
      // Ensure the other user's last seen time is not null and is after or at the same moment as the last message time
      if (otherUserLastSeen != null && lastMessageTime != null) {
        return otherUserLastSeen.isAfter(lastMessageTime!) ||
            otherUserLastSeen.isAtSameMomentAs(lastMessageTime!);
      }
    }
    return false;
  }
}