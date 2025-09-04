import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/models/friendship_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';

/// FriendsController manages all logic related to the user's friends list.
/// It handles fetching, searching, and managing friends, as well as initiating
/// chats and handling friend removal/blocking.
///
/// This controller is responsible for:
/// - Real-time streaming of friendship data from Firestore
/// - Efficient parallel loading of friend user details
/// - Search functionality with debounced filtering
/// - Friend removal and blocking with confirmation dialogs
/// - Chat initiation with friends
/// - Online status and last seen tracking
/// - Memory management with proper stream subscription handling
/// - Navigation to friend requests and chat screens
class FriendsController extends GetxController {

  // ==================== DEPENDENCIES ====================

  /// Service dependencies for interacting with Firestore and authentication.
  /// These provide data access and user management functionality.

  /// Service for Firestore database operations (friendships, users, blocking)
  final FirestoreService _firestoreService = FirestoreService();

  /// Authentication controller to access current user information
  final AuthController _authController = Get.find<AuthController>();

  // ==================== REACTIVE STATE VARIABLES ====================

  /// Reactive state variables for the UI using GetX observables.
  /// These automatically trigger UI updates when values change.

  /// The raw friendship documents from Firestore containing relationship data
  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs;

  /// The detailed user models for each friend with profile information
  final RxList<UserModel> _friends = <UserModel>[].obs;

  /// Tracks global loading state for operations like remove/block/chat
  final RxBool _isLoading = false.obs;

  /// Stores any error messages that occur during operations
  final RxString _error = ''.obs;

  /// The user's current search input for filtering friends
  final RxString _searchQuery = ''.obs;

  /// The friends list after applying search filters
  final RxList<UserModel> _filteredFriends = <UserModel>[].obs;

  // ==================== STREAM MANAGEMENT ====================

  /// A StreamSubscription to properly manage the Firestore stream and prevent memory leaks.
  /// This allows us to cancel the subscription when the controller is disposed.
  StreamSubscription? _friendshipsSubscription;

  // ==================== PUBLIC GETTERS ====================

  /// Public getters to access the reactive state without exposing Rx objects.
  /// These provide a clean API for UI components to access controller state.

  /// Returns the raw friendship relationship data
  List<FriendshipModel> get friendships => _friendships;

  /// Returns the complete list of friends with their profile data
  List<UserModel> get friends => _friends;

  /// Returns the filtered list of friends based on current search query
  List<UserModel> get filteredFriends => _filteredFriends;

  /// Returns true if any operation is currently in progress
  bool get isLoading => _isLoading.value;

  /// Returns current error message or empty string if no error
  String get error => _error.value;

  /// Returns the current search query string
  String get searchQuery => _searchQuery.value;

  // ==================== LIFECYCLE METHODS ====================

  /// Called when the controller is initialized.
  /// Sets up data streams and search functionality.
  @override
  void onInit() {
    super.onInit();
    // Start loading friends data from Firestore
    _loadFriends();

    // Debounce the search query to avoid excessive filtering on every keystroke.
    // The filter function will only run after the user stops typing for 300ms.
    // This improves performance and reduces unnecessary computations.
    debounce(
      _searchQuery,
          (_) => _filterFriends(),
      time: const Duration(milliseconds: 300),
    );
  }

  /// Called when the controller is closed and disposed.
  /// Performs cleanup to prevent memory leaks.
  @override
  void onClose() {
    // Cancel the stream subscription to prevent memory leaks and unnecessary data fetching.
    // This is crucial for proper resource management in Flutter apps.
    _friendshipsSubscription?.cancel();
    super.onClose();
  }

  // ==================== DATA LOADING AND STREAMING ====================

  /// Fetches the list of friendships from Fire-store in real-time.
  /// This creates a reactive connection where friendship changes automatically update the UI.
  void _loadFriends() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      // Cancel any previous subscription before creating a new one.
      // This prevents multiple subscriptions and potential memory leaks.
      _friendshipsSubscription?.cancel();

      // Listen to the stream of friendship documents from Firestore.
      // This provides real-time updates when friendships are added/removed.
      _friendshipsSubscription = _firestoreService
          .getFriendsStream(currentUserId)
          .listen((friendshipList) {
        // Update the reactive friendships list
        _friendships.value = friendshipList;
        // After fetching the friendships, load the detailed user data for each friend.
        // This two-step process optimizes data loading by first getting relationships,
        // then fetching detailed profile information.
        _loadFriendDetails(currentUserId, friendshipList);
      });
    }
  }

  /// Loads the detailed UserModel for each friend using parallel processing.
  /// This method efficiently fetches user details for all friends simultaneously
  /// rather than making sequential database calls.
  Future<void> _loadFriendDetails(String currentUserId, List<FriendshipModel> friendshipList) async {
    try {
      // Set loading state to show progress indicators
      _isLoading.value = true;
      List<UserModel> friendUsers = [];

      // Use Future.wait to fetch user details in parallel, which is much more efficient
      // than sequential fetching. This reduces total loading time significantly.
      final futures = friendshipList.map((friendship) async {
        // Extract the friend's user ID from the friendship relationship
        String friendId = friendship.getOtherUserId(currentUserId);
        // Fetch the complete user profile for this friend
        return await _firestoreService.getUser(friendId);
      }).toList();

      // Wait for all user detail fetches to complete simultaneously
      final results = await Future.wait(futures);

      // Process the results and build the friends list
      for (var friend in results) {
        if (friend != null) {
          friendUsers.add(friend);
        }
      }

      // Update the reactive friends list with complete user data
      _friends.value = friendUsers;
      // Filter the list after loading the friends to apply any active search
      _filterFriends();
    } catch (e) {
      // Handle loading errors gracefully
      _error.value = e.toString();
    } finally {
      // Always reset loading state
      _isLoading.value = false;
    }
  }

  // ==================== SEARCH AND FILTERING ====================

  /// Filters the friends list based on the search query.
  /// This provides real-time search functionality across friend names and emails.
  void _filterFriends() {
    final query = _searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      // If the query is empty, show all friends without filtering
      _filteredFriends.value = _friends;
    } else {
      // Filter the friends list where the display name or email contains the query.
      // Case-insensitive search provides better user experience.
      _filteredFriends.value = _friends.where((friend) {
        return friend.displayName.toLowerCase().contains(query) ||
            friend.email.toLowerCase().contains(query);
      }).toList();
    }
  }

  /// Updates the search query and triggers the filter.
  /// This is called when the user types in the search field.
  void updateSearchQuery(String query) {
    _searchQuery.value = query;
    // The debounced filter will automatically trigger after 300ms
  }

  /// Clears the search query and resets the filtered list.
  /// This shows all friends again and clears the search input.
  void clearSearch() {
    _searchQuery.value = '';
    // This will trigger the filter and show all friends
  }

  /// Refreshes the friends list manually, often used in a pull-to-refresh action.
  /// This allows users to manually refresh data if needed.
  Future<void> refreshFriends() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      // Restart the friends loading process
      _loadFriends();
    }
  }

  // ==================== FRIEND MANAGEMENT OPERATIONS ====================

  /// Removes a friend after user confirmation.
  /// This breaks the friendship relationship but doesn't block the user.
  Future<void> removeFriend(UserModel friend) async {
    try {
      // Show a confirmation dialog before proceeding to prevent accidental removal.
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Remove Friend'),
          content: Text(
            'Are you sure you want to remove ${friend.displayName} from your friends?',
          ),
          actions: [
            // Cancel button - returns false
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            // Remove button - returns true, styled in red to indicate action
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      // Proceed only if user confirmed the action
      if (result == true) {
        _isLoading.value = true;
        final currentUserId = _authController.user?.uid;

        if (currentUserId != null) {
          // Call the service to remove the friendship from Firestore.
          // This breaks the bidirectional friendship relationship.
          await _firestoreService.removeFriendship(currentUserId, friend.id);
          Get.snackbar('Success', '${friend.displayName} removed from friends');
          // The stream listener will automatically update the UI after the change.
        }
      }
    } catch (e) {
      // Handle removal errors gracefully
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to remove friend: ${e.toString()}');
    } finally {
      // Always reset loading state
      _isLoading.value = false;
    }
  }

  /// Blocks a user, which also removes them as a friend.
  /// This is a more severe action that prevents all future communication.
  Future<void> blockFriend(UserModel friend) async {
    try {
      // Show a confirmation dialog explaining the consequences of blocking.
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Block User'),
          content: Text(
            'Are you sure you want to block ${friend.displayName}? This will remove them from your friends and prevent them from messaging you.',
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            // Block button - styled in red to indicate severity
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Block'),
            ),
          ],
        ),
      );

      // Proceed only if user confirmed the blocking action
      if (result == true) {
        _isLoading.value = true;
        final currentUserId = _authController.user?.uid;

        if (currentUserId != null) {
          // Call the service to block the user.
          // This removes the friendship and prevents future communication.
          await _firestoreService.blockUser(currentUserId, friend.id);
          Get.snackbar('Success', '${friend.displayName} has been blocked');
          // The stream listener automatically handles the UI update.
        }
      }
    } catch (e) {
      // Handle blocking errors
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to block user: ${e.toString()}');
    } finally {
      // Reset loading state
      _isLoading.value = false;
    }
  }

  // ==================== CHAT NAVIGATION ====================

  /// Navigates to the chat screen with a selected friend.
  /// This initiates a new chat or continues an existing conversation.
  Future<void> startChat(UserModel friend) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        // Navigate to the chat screen and pass the other user's details.
        // The chat controller will handle chat ID creation if it's a new conversation.
        Get.toNamed(
          AppRoutes.chat,
          arguments: {
            'chatId': null, // Indicate that the chat ID is not yet known.
            'otherUser': friend, // Pass friend's profile data
            'isNewChat': true, // Flag indicating this is a new chat initiation
          },
        );
      }
    } catch (e) {
      // Handle chat initiation errors
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to start chat: ${e.toString()}');
    } finally {
      // Reset loading state
      _isLoading.value = false;
    }
  }

  // ==================== UTILITY AND FORMATTING METHODS ====================

  /// Formats the last seen timestamp of a friend into a user-friendly string.
  /// This provides intuitive status information about when friends were last active.
  String getLastSeenText(UserModel friend) {
    if (friend.isOnline) {
      // Friend is currently online
      return 'Online';
    } else {
      // Calculate time difference for offline friends
      final now = DateTime.now();
      final difference = now.difference(friend.lastSeen);

      if (difference.inMinutes < 1) {
        // Very recently active
        return 'Just now';
      } else if (difference.inHours < 1) {
        // Active within the last hour
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        // Active today
        return 'Last seen ${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        // Active within the week
        return 'Last seen ${difference.inDays}d ago';
      } else {
        // Older activity - show full date for clarity
        return 'Last seen ${friend.lastSeen.day}/${friend.lastSeen.month}/${friend.lastSeen.year}';
      }
    }
  }

  // ==================== NAVIGATION METHODS ====================

  /// Navigates to the friend requests screen.
  /// This allows users to manage incoming and outgoing friend requests.
  void openFriendRequests() {
    Get.toNamed(AppRoutes.friendRequests);
  }

  /// Clears the current error message.
  /// Useful for resetting error state when user dismisses errors
  /// or when starting new operations that should have clean error state.
  void clearError() {
    _error.value = '';
  }
}
