import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/models/friend_request_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';

// FriendRequestsController manages all logic related to friend requests,
// including fetching, accepting, declining, and displaying them.
class FriendRequestsController extends GetxController {
  // Dependencies are injected for a clean, modular design.
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  // Reactive state variables. These are observable and automatically
  // update the UI when their values change.
  final RxList<FriendRequestModel> _receivedRequests = <FriendRequestModel>[].obs; // List of incoming friend requests.
  final RxList<FriendRequestModel> _sentRequests = <FriendRequestModel>[].obs; // List of requests sent by the current user.
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs; // Map to quickly look up users by ID.
  final RxBool _isLoading = false.obs; // Tracks global loading state.
  final RxString _error = ''.obs; // Stores any error messages.
  final RxInt _selectedTabIndex = 0.obs; // Tracks the currently selected tab (e.g., received vs. sent).

  // Public getters to provide read-only access to the reactive state.
  List<FriendRequestModel> get receivedRequests => _receivedRequests;
  List<FriendRequestModel> get sentRequests => _sentRequests;
  Map<String, UserModel> get users => _users;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  int get selectedTabIndex => _selectedTabIndex.value;

  /// Called automatically by GetX when the controller is first created.
  /// Used to set up stream listeners for friend requests and user data.
  @override
  void onInit() {
    super.onInit();
    _loadFriendRequests();
    _loadUsers();
  }

  /// Binds the `_receivedRequests` and `_sentRequests` lists to real-time
  /// Firestore streams.
  void _loadFriendRequests() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      // Stream for requests where the current user is the receiver.
      _receivedRequests.bindStream(_firestoreService.getFriendRequestsStream(currentUserId));
      // Stream for requests where the current user is the sender.
      _sentRequests.bindStream(_firestoreService.getSentFriendRequestsStream(currentUserId));
    }
  }

  /// Binds the `_users` map to a stream of all user data from Firestore.
  /// This allows for easy lookup of user details based on their ID.
  void _loadUsers() {
    _users.bindStream(_firestoreService.getAllUsersStream().map((userList) {
      // Convert the list of users into a map for efficient access.
      Map<String, UserModel> userMap = {};
      for (var user in userList) {
        userMap[user.id] = user;
      }
      return userMap;
    }));
  }

  /// Updates the selected tab index for the UI.
  void changeTab(int index) {
    _selectedTabIndex.value = index;
  }

  /// Retrieves a UserModel from the local cache based on their ID.
  UserModel? getUser(String userId) {
    return _users[userId];
  }

  /// Accepts a friend request and updates its status in Firestore.
  Future<void> acceptFriendRequest(FriendRequestModel request) async {
    try {
      _isLoading.value = true;
      // Call the service to update the request status to 'accepted'.
      await _firestoreService.respondToFriendRequest(request.id, FriendRequestStatus.accepted);
      Get.snackbar('Success', 'Friend request accepted');
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to accept friend request: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Declines a friend request and updates its status in Firestore.
  Future<void> declineFriendRequest(FriendRequestModel request) async {
    try {
      _isLoading.value = true;
      // Call the service to update the request status to 'declined'.
      await _firestoreService.respondToFriendRequest(request.id, FriendRequestStatus.declined);
      Get.snackbar('Success', 'Friend request declined');
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to decline friend request: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Unblocks a user, allowing communication to be re-established.
  Future<void> unblockUser(String userId) async {
    try {
      _isLoading.value = true;
      // The `unblockUser` method requires both the current user's ID and the user to unblock.
      await _firestoreService.unblockUser(_authController.user!.uid, userId);
      Get.snackbar('Success', 'User unblocked successfully');
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to unblock user: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Formats a DateTime object into a user-friendly string (e.g., "5m ago", "3d ago").
  String getRequestTimeText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Fallback to a full date format for older requests.
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Provides a string representation of a friend request status.
  String getStatusText(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return 'Pending';
      case FriendRequestStatus.accepted:
        return 'Accepted';
      case FriendRequestStatus.declined:
        return 'Declined';
    }
  }

  /// Provides a color for a friend request status.
  Color getStatusColor(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return Colors.orange;
      case FriendRequestStatus.accepted:
        return Colors.green;
      case FriendRequestStatus.declined:
        return Colors.red;
    }
  }

  /// Clears the current error message.
  void clearError() {
    _error.value = '';
  }
}