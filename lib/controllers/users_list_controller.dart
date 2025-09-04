import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/models/friend_request_model.dart';
import 'package:chat_app_flutter/models/friendship_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';

/// Enumeration defining all possible relationship states between users
/// This provides type-safe relationship status management throughout the app
enum UserRelationshipStatus {
  none,                     // No relationship exists
  friendRequestSent,        // Current user has sent a friend request
  friendRequestReceived,    // Current user has received a friend request
  friends,                  // Users are friends
  blocked,                  // User is blocked
}

/// UsersListController manages user discovery and relationship management.
/// This controller handles the complex logic of displaying all users in the app,
/// managing different relationship states, and providing appropriate actions
/// for each relationship type with real-time updates and optimistic UI updates.
///
/// This controller is responsible for:
/// - Loading and filtering all app users excluding current user
/// - Real-time tracking of relationship status between users
/// - Friend request sending, accepting, declining, and canceling
/// - Search functionality across user names and emails
/// - Chat initiation with friends (with relationship validation)
/// - Optimistic UI updates with error rollback for better UX
/// - Status-based button text, icons, and colors for clear user interface
/// - Online status tracking and last seen formatting
/// - Integration with multiple Firestore streams for real-time updates
class UsersListController extends GetxController {

  // ==================== DEPENDENCIES ====================

  /// Service dependencies for data access and functionality
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  /// UUID generator for creating unique friend request IDs
  final Uuid _uuid = const Uuid();

  // ==================== REACTIVE STATE VARIABLES ====================

  /// All users in the app (excluding current user after filtering)
  final RxList<UserModel> _users = <UserModel>[].obs;

  /// Filtered users based on search query
  final RxList<UserModel> _filteredUsers = <UserModel>[].obs;

  /// Loading state for user actions (send request, accept, etc.)
  final RxBool _isLoading = false.obs;

  /// Error message storage for user feedback
  final RxString _error = ''.obs;

  /// Current search query for filtering users
  final RxString _searchQuery = ''.obs;

  /// Map tracking relationship status for each user (userId -> status)
  /// This provides O(1) lookup for relationship information
  final RxMap<String, UserRelationshipStatus> _userRelationships =
      <String, UserRelationshipStatus>{}.obs;

  /// Real-time streams for relationship data
  /// Friend requests sent by current user
  final RxList<FriendRequestModel> _sentRequests = <FriendRequestModel>[].obs;

  /// Friend requests received by current user
  final RxList<FriendRequestModel> _receivedRequests =
      <FriendRequestModel>[].obs;

  /// Active friendships involving current user
  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs;

  // ==================== PUBLIC GETTERS ====================

  /// Public getters providing controlled access to reactive state
  List<UserModel> get users => _users;
  List<UserModel> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get searchQuery => _searchQuery.value;
  Map<String, UserRelationshipStatus> get userRelationships =>
      _userRelationships;

  // ==================== LIFECYCLE METHODS ====================

  /// Controller initialization - sets up all data streams and search functionality
  @override
  void onInit() {
    super.onInit();
    // Load user data and relationship information
    _loadUsers();
    _loadRelationships();

    // Listen to search query changes with debouncing for performance
    // Debouncing prevents excessive filtering on every keystroke
    debounce(
      _searchQuery,
          (_) => _filterUsers(),
      time: const Duration(milliseconds: 300),
    );
  }

  // ==================== DATA LOADING AND STREAMING ====================

  /// Sets up real-time user data streaming and filtering
  void _loadUsers() {
    // Bind to all users stream from Firestore for real-time updates
    _users.bindStream(_firestoreService.getAllUsersStream());

    // Filter out current user and update filtered list when users change
    ever(_users, (List<UserModel> userList) {
      final currentUserId = _authController.user?.uid;
      // Exclude current user from the list since they can't interact with themselves
      final otherUsers = userList
          .where((user) => user.id != currentUserId)
          .toList();

      if (_searchQuery.value.isEmpty) {
        // No search query - show all other users
        _filteredUsers.value = otherUsers;
      } else {
        // Apply current search filter
        _filterUsers();
      }
    });
  }

  /// Sets up real-time relationship data streaming
  /// This manages multiple Firestore streams to track all relationship states
  void _loadRelationships() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      // Load sent friend requests - requests current user has sent to others
      _sentRequests.bindStream(
        _firestoreService.getSentFriendRequestsStream(currentUserId),
      );

      // Load received friend requests - requests others have sent to current user
      _receivedRequests.bindStream(
        _firestoreService.getFriendRequestsStream(currentUserId),
      );

      // Load friendships - active friend relationships involving current user
      _friendships.bindStream(
        _firestoreService.getFriendsStream(currentUserId),
      );

      // Update relationship status when any of these streams change
      // This ensures UI reflects current relationship state in real-time
      ever(_sentRequests, (_) => _updateAllRelationshipStatuses());
      ever(_receivedRequests, (_) => _updateAllRelationshipStatuses());
      ever(_friendships, (_) => _updateAllRelationshipStatuses());

      // Initial load - update statuses when users are first loaded
      ever(_users, (_) => _updateAllRelationshipStatuses());
    }
  }

  // ==================== RELATIONSHIP STATUS MANAGEMENT ====================

  /// Updates relationship status for all users based on current data
  /// This method recalculates all relationship statuses whenever data changes
  void _updateAllRelationshipStatuses() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    // Calculate and cache relationship status for each user
    for (var user in _users) {
      if (user.id != currentUserId) {
        final status = _calculateUserRelationshipStatus(user.id);
        _userRelationships[user.id] = status;
      }
    }
  }

  /// Calculates the relationship status between current user and specified user
  /// This method prioritizes different relationship types in a specific order
  UserRelationshipStatus _calculateUserRelationshipStatus(String userId) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return UserRelationshipStatus.none;

    // Check if they are friends (highest priority relationship)
    final friendship = _friendships.firstWhereOrNull(
          (f) =>
      (f.user1Id == currentUserId && f.user2Id == userId) ||
          (f.user1Id == userId && f.user2Id == currentUserId),
    );

    if (friendship != null) {
      if (friendship.isBlocked) {
        // Blocked relationship takes precedence over friendship
        return UserRelationshipStatus.blocked;
      } else {
        // Active friendship
        return UserRelationshipStatus.friends;
      }
    }

    // Check for sent friend requests (pending outgoing requests)
    final sentRequest = _sentRequests.firstWhereOrNull(
          (r) => r.receiverId == userId && r.status == FriendRequestStatus.pending,
    );
    if (sentRequest != null) {
      return UserRelationshipStatus.friendRequestSent;
    }

    // Check for received friend requests (pending incoming requests)
    final receivedRequest = _receivedRequests.firstWhereOrNull(
          (r) => r.senderId == userId && r.status == FriendRequestStatus.pending,
    );
    if (receivedRequest != null) {
      return UserRelationshipStatus.friendRequestReceived;
    }

    // No relationship exists
    return UserRelationshipStatus.none;
  }

  // ==================== SEARCH AND FILTERING ====================

  /// Filters users based on search query across name and email
  void _filterUsers() {
    final currentUserId = _authController.user?.uid;
    final query = _searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      // No search query - show all users except current user
      _filteredUsers.value = _users
          .where((user) => user.id != currentUserId)
          .toList();
    } else {
      // Filter users by display name or email containing search query
      _filteredUsers.value = _users.where((user) {
        return user.id != currentUserId &&
            (user.displayName.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query));
      }).toList();
    }
  }

  /// Updates search query and triggers filtering
  void updateSearchQuery(String query) {
    _searchQuery.value = query;
    // Debounced filtering will trigger automatically
  }

  /// Clears search query and shows all users
  void clearSearch() {
    _searchQuery.value = '';
    // This will trigger filtering to show all users
  }

  // ==================== FRIEND REQUEST OPERATIONS ====================

  /// Sends a friend request with optimistic UI updates and error rollback
  Future<void> sendFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        // Create friend request model with unique ID
        final request = FriendRequestModel(
          id: _uuid.v4(),
          senderId: currentUserId,
          receiverId: user.id,
          createdAt: DateTime.now(),
        );

        // Immediately update the UI for better user experience (optimistic update)
        _userRelationships[user.id] = UserRelationshipStatus.friendRequestSent;

        // Send request to Firestore
        await _firestoreService.sendFriendRequest(request);
        Get.snackbar('Success', 'Friend request sent to ${user.displayName}');
      }
    } catch (e) {
      // Revert the UI change on error (rollback optimistic update)
      _userRelationships[user.id] = UserRelationshipStatus.none;
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to send friend request: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cancels a sent friend request with optimistic UI updates
  Future<void> cancelFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        // Find the pending friend request
        final request = _sentRequests.firstWhereOrNull(
              (r) =>
          r.receiverId == user.id &&
              r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          // Immediately update the UI (optimistic update)
          _userRelationships[user.id] = UserRelationshipStatus.none;

          // Cancel request in Firestore
          await _firestoreService.cancelFriendRequest(request.id);
          Get.snackbar('Success', 'Friend request cancelled');
        }
      }
    } catch (e) {
      // Revert the UI change on error
      _userRelationships[user.id] = UserRelationshipStatus.friendRequestSent;
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to cancel friend request: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Accepts a received friend request with optimistic UI updates
  Future<void> acceptFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        // Find the pending friend request from this user
        final request = _receivedRequests.firstWhereOrNull(
              (r) =>
          r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          // Immediately update the UI to show friendship (optimistic update)
          _userRelationships[user.id] = UserRelationshipStatus.friends;

          // Accept the request in Firestore (creates friendship)
          await _firestoreService.respondToFriendRequest(
            request.id,
            FriendRequestStatus.accepted,
          );
          Get.snackbar('Success', 'Friend request accepted');
        }
      }
    } catch (e) {
      // Revert the UI change on error
      _userRelationships[user.id] =
          UserRelationshipStatus.friendRequestReceived;
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to accept friend request: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Declines a received friend request with optimistic UI updates
  Future<void> declineFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        // Find the pending friend request from this user
        final request = _receivedRequests.firstWhereOrNull(
              (r) =>
          r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          // Immediately update the UI (optimistic update)
          _userRelationships[user.id] = UserRelationshipStatus.none;

          // Decline the request in Firestore
          await _firestoreService.respondToFriendRequest(
            request.id,
            FriendRequestStatus.declined,
          );
          Get.snackbar('Success', 'Friend request declined');
        }
      }
    } catch (e) {
      // Revert the UI change on error
      _userRelationships[user.id] =
          UserRelationshipStatus.friendRequestReceived;
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to decline friend request: ${e.toString()}',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // ==================== CHAT INITIATION ====================

  /// Starts a chat with a user after validating friendship status
  /// Only friends can chat with each other for privacy and security
  Future<void> startChat(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        // Check if they are friends first - only friends can chat
        final relationship =
            _userRelationships[user.id] ?? UserRelationshipStatus.none;
        if (relationship != UserRelationshipStatus.friends) {
          Get.snackbar(
            'Info',
            'You can only chat with friends. Send a friend request first.',
          );
          return;
        }

        // Create or get existing chat between the two users
        final chatId = await _firestoreService.createOrGetChat(
          currentUserId,
          user.id,
        );

        // Navigate to chat screen with chat ID and user information
        Get.toNamed(
          AppRoutes.chat,
          arguments: {'chatId': chatId, 'otherUser': user},
        );
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to start chat: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  // ==================== UTILITY METHODS FOR UI ====================

  /// Gets the relationship status for a specific user
  UserRelationshipStatus getUserRelationshipStatus(String userId) {
    return _userRelationships[userId] ?? UserRelationshipStatus.none;
  }

  /// Returns appropriate button text based on relationship status
  String getRelationshipButtonText(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none:
        return 'Add Friend';
      case UserRelationshipStatus.friendRequestSent:
        return 'Request Sent';
      case UserRelationshipStatus.friendRequestReceived:
        return 'Accept Request';
      case UserRelationshipStatus.friends:
        return 'Message';
      case UserRelationshipStatus.blocked:
        return 'Blocked';
    }
  }

  /// Returns appropriate icon for relationship status button
  IconData getRelationshipButtonIcon(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none:
        return Icons.person_add;          // Add person icon
      case UserRelationshipStatus.friendRequestSent:
        return Icons.access_time;         // Clock icon (waiting)
      case UserRelationshipStatus.friendRequestReceived:
        return Icons.check;               // Check mark (accept)
      case UserRelationshipStatus.friends:
        return Icons.chat_bubble_outline; // Chat bubble icon
      case UserRelationshipStatus.blocked:
        return Icons.block;               // Block icon
    }
  }

  /// Returns appropriate color for relationship status button
  Color getRelationshipButtonColor(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none:
        return Colors.blue;               // Neutral action
      case UserRelationshipStatus.friendRequestSent:
        return Colors.orange;             // Pending state
      case UserRelationshipStatus.friendRequestReceived:
        return Colors.green;              // Positive action
      case UserRelationshipStatus.friends:
        return Colors.blue;               // Chat action
      case UserRelationshipStatus.blocked:
        return Colors.red;                // Blocked state
    }
  }

  /// Handles the appropriate action based on current relationship status
  /// This is the main method called when user taps the relationship button
  void handleRelationshipAction(UserModel user) {
    final status = getUserRelationshipStatus(user.id);

    switch (status) {
      case UserRelationshipStatus.none:
      // No relationship - send friend request
        sendFriendRequest(user);
        break;
      case UserRelationshipStatus.friendRequestSent:
      // Request already sent - show info message
        Get.snackbar('Info', 'Friend request already sent');
        break;
      case UserRelationshipStatus.friendRequestReceived:
      // Accept the received friend request
        acceptFriendRequest(user);
        break;
      case UserRelationshipStatus.friends:
      // Start chat with friend
        startChat(user);
        break;
      case UserRelationshipStatus.blocked:
      // User is blocked - show info message
        Get.snackbar('Info', 'This user is blocked');
        break;
    }
  }

  // ==================== STATUS FORMATTING ====================

  /// Formats user's last seen status into human-readable text
  /// Provides progressive detail based on how recently user was active
  String getLastSeenText(UserModel user) {
    if (user.isOnline) {
      // User is currently online
      return 'Online';
    } else {
      // Calculate time difference for offline status
      final now = DateTime.now();
      final difference = now.difference(user.lastSeen);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        // Within the last hour
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        // Within the last day
        return 'Last seen ${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        // Within the last week
        return 'Last seen ${difference.inDays}d ago';
      } else {
        // Older than a week - show full date
        return 'Last seen ${user.lastSeen.day}/${user.lastSeen.month}/${user.lastSeen.year}';
      }
    }
  }

  /// Clears current error message
  void clearError() {
    _error.value = '';
  }
}
