import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/models/friend_request_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';

/// FriendRequestsController manages all logic related to friend requests,
/// including fetching, accepting, declining, and displaying them.
///
/// This controller handles:
/// - Real-time streaming of incoming and outgoing friend requests
/// - User data caching for efficient profile information access
/// - Friend request acceptance and decline operations
/// - User unblocking functionality
/// - Tab navigation between received and sent requests
/// - Time formatting for request timestamps
/// - Status display with appropriate colors and text
/// - Error handling and user feedback for all operations
class FriendRequestsController extends GetxController {

  // ==================== DEPENDENCIES ====================

  /// Dependencies are injected for a clean, modular design.
  /// These services provide data access and authentication functionality.

  /// Service for Firestore database operations (friend requests, users, blocking)
  final FirestoreService _firestoreService = FirestoreService();

  /// Authentication controller to access current user information
  final AuthController _authController = Get.find<AuthController>();

  // ==================== REACTIVE STATE VARIABLES ====================

  /// Reactive state variables. These are observable and automatically
  /// update the UI when their values change using GetX's reactive system.

  /// List of incoming friend requests where current user is the receiver
  final RxList<FriendRequestModel> _receivedRequests = <FriendRequestModel>[].obs;

  /// List of requests sent by the current user where they are the sender
  final RxList<FriendRequestModel> _sentRequests = <FriendRequestModel>[].obs;

  /// Map to quickly look up users by ID for efficient profile data access
  /// Structure: {userId: UserModel} for O(1) lookup performance
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;

  /// Tracks global loading state during accept/decline/unblock operations
  final RxBool _isLoading = false.obs;

  /// Stores any error messages that occur during operations
  final RxString _error = ''.obs;

  /// Tracks the currently selected tab index (0 = received, 1 = sent)
  final RxInt _selectedTabIndex = 0.obs;

  // ==================== PUBLIC GETTERS ====================

  /// Public getters to provide read-only access to the reactive state.
  /// These expose current state without allowing external modification.

  /// Returns list of friend requests received by current user
  List<FriendRequestModel> get receivedRequests => _receivedRequests;

  /// Returns list of friend requests sent by current user
  List<FriendRequestModel> get sentRequests => _sentRequests;

  /// Returns map of all users for profile information lookup
  Map<String, UserModel> get users => _users;

  /// Returns true if any operation is currently in progress
  bool get isLoading => _isLoading.value;

  /// Returns current error message or empty string if no error
  String get error => _error.value;

  /// Returns currently selected tab index for UI state management
  int get selectedTabIndex => _selectedTabIndex.value;

  // ==================== LIFECYCLE METHODS ====================

  /// Called automatically by GetX when the controller is first created.
  /// Used to set up stream listeners for friend requests and user data.
  @override
  void onInit() {
    super.onInit();
    // Initialize real-time data streams
    _loadFriendRequests();
    _loadUsers();
  }

  // ==================== DATA LOADING AND STREAMING ====================

  /// Binds the `_receivedRequests` and `_sentRequests` lists to real-time
  /// Firestore streams. This creates reactive connections where changes in
  /// the database automatically update the UI without manual refreshing.
  void _loadFriendRequests() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      // Stream for requests where the current user is the receiver.
      // These are friend requests sent TO the current user.
      _receivedRequests.bindStream(_firestoreService.getFriendRequestsStream(currentUserId));

      // Stream for requests where the current user is the sender.
      // These are friend requests sent BY the current user.
      _sentRequests.bindStream(_firestoreService.getSentFriendRequestsStream(currentUserId));
    }
  }

  /// Binds the `_users` map to a stream of all user data from Firestore.
  /// This allows for easy lookup of user details based on their ID without
  /// making individual database calls for each user.
  void _loadUsers() {
    // Transform the user list stream into a map for efficient O(1) lookups
    _users.bindStream(_firestoreService.getAllUsersStream().map((userList) {
      // Convert the list of users into a map for efficient access.
      // This eliminates the need for linear searches when displaying user info.
      Map<String, UserModel> userMap = {};
      for (var user in userList) {
        userMap[user.id] = user;
      }
      return userMap;
    }));
  }

  // ==================== UI STATE MANAGEMENT ====================

  /// Updates the selected tab index for the UI.
  /// This manages the tab navigation between received and sent friend requests.
  void changeTab(int index) {
    _selectedTabIndex.value = index;
  }

  /// Retrieves a UserModel from the local cache based on their ID.
  /// This provides efficient access to user profile information without database calls.
  /// Returns null if the user is not found in the cached data.
  UserModel? getUser(String userId) {
    return _users[userId];
  }

  // ==================== FRIEND REQUEST OPERATIONS ====================

  /// Accepts a friend request and updates its status in Firestore.
  /// This creates a friendship relationship between the two users.
  Future<void> acceptFriendRequest(FriendRequestModel request) async {
    try {
      // Set loading state to show progress indicators
      _isLoading.value = true;

      // Call the service to update the request status to 'accepted'.
      // This also creates the friendship relationship in the database.
      await _firestoreService.respondToFriendRequest(request.id, FriendRequestStatus.accepted);

      // Show success feedback to user
      Get.snackbar('Success', 'Friend request accepted');
    } catch (e) {
      // Handle acceptance errors and provide user feedback
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to accept friend request: ${e.toString()}');
    } finally {
      // Always reset loading state
      _isLoading.value = false;
    }
  }

  /// Declines a friend request and updates its status in Firestore.
  /// This rejects the friendship without creating any relationship.
  Future<void> declineFriendRequest(FriendRequestModel request) async {
    try {
      // Set loading state for UI feedback
      _isLoading.value = true;

      // Call the service to update the request status to 'declined'.
      // This permanently rejects the friend request.
      await _firestoreService.respondToFriendRequest(request.id, FriendRequestStatus.declined);

      // Show success confirmation to user
      Get.snackbar('Success', 'Friend request declined');
    } catch (e) {
      // Handle decline errors gracefully
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to decline friend request: ${e.toString()}');
    } finally {
      // Reset loading state
      _isLoading.value = false;
    }
  }

  // ==================== USER MANAGEMENT OPERATIONS ====================

  /// Unblocks a user, allowing communication to be re-established.
  /// This removes the user from the current user's blocked list, enabling
  /// them to send messages and friend requests again.
  Future<void> unblockUser(String userId) async {
    try {
      // Set loading state for user feedback
      _isLoading.value = true;

      // The `unblockUser` method requires both the current user's ID and the user to unblock.
      // This removes the blocking relationship from the database.
      await _firestoreService.unblockUser(_authController.user!.uid, userId);

      // Confirm successful unblocking to user
      Get.snackbar('Success', 'User unblocked successfully');
    } catch (e) {
      // Handle unblock errors with appropriate feedback
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to unblock user: ${e.toString()}');
    } finally {
      // Reset loading state
      _isLoading.value = false;
    }
  }

  // ==================== UTILITY AND FORMATTING METHODS ====================

  /// Formats a DateTime object into a user-friendly string (e.g., "5m ago", "3d ago").
  /// This provides intuitive time representations for when friend requests were sent.
  String getRequestTimeText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      // Very recent requests (less than a minute)
      return 'Just now';
    } else if (difference.inHours < 1) {
      // Recent requests within the hour
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      // Requests from today
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      // Requests from this week
      return '${difference.inDays}d ago';
    } else {
      // Fallback to a full date format for older requests.
      // This provides clear dates for requests older than a week.
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Provides a string representation of a friend request status.
  /// This converts the enum status into user-readable text for display.
  String getStatusText(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
      // Request is waiting for response
        return 'Pending';
      case FriendRequestStatus.accepted:
      // Request was accepted, users are now friends
        return 'Accepted';
      case FriendRequestStatus.declined:
      // Request was declined/rejected
        return 'Declined';
    }
  }

  /// Provides a color for a friend request status.
  /// This enables visual status indication in the UI with appropriate colors.
  Color getStatusColor(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
      // Orange for pending requests (neutral, waiting state)
        return Colors.orange;
      case FriendRequestStatus.accepted:
      // Green for accepted requests (positive outcome)
        return Colors.green;
      case FriendRequestStatus.declined:
      // Red for declined requests (negative outcome)
        return Colors.red;
    }
  }

  /// Clears the current error message.
  /// Useful for resetting error state when user dismisses errors
  /// or when starting new operations that should have clean error state.
  void clearError() {
    _error.value = '';
  }
}
