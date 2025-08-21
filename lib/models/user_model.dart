/// A model class representing a user profile within the application.
class UserModel {
  /// The unique identifier for the user.
  final String id;

  /// The user's email address.
  final String email;

  /// The user's display name, used for public-facing profiles.
  final String displayName;

  /// The URL to the user's profile picture.
  final String photoURL;

  /// A boolean indicating the user's online status.
  final bool isOnline;

  /// The timestamp of the last time the user was seen active.
  final DateTime lastSeen;

  /// The timestamp when the user account was created.
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL = '',
    this.isOnline = false,
    required this.lastSeen,
    required this.createdAt,
  });

  /// Converts a [UserModel] instance into a map, typically for storing in a database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isOnline': isOnline,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a [UserModel] instance from a map, typically for retrieving data from a database.
  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  /// Creates a new [UserModel] instance by copying the existing one and optionally updating some fields.
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}