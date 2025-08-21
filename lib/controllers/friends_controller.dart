import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/models/friendship_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';

// FriendsController manages all logic related to the user's friends list.
// It handles fetching, searching, and managing friends, as well as initiating
// chats and handling friend removal/blocking.
class FriendsController extends GetxController {
  // Service dependencies for interacting with Firestore.
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  // Reactive state variables for the UI.
  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs; // The raw friendship documents from Firestore.
  final RxList<UserModel> _friends = <UserModel>[].obs; // The detailed user models for each friend.
  final RxBool _isLoading = false.obs; // Tracks global loading state.
  final RxString _error = ''.obs; // Stores any error messages.
  final RxString _searchQuery = ''.obs; // The user's search input.
  final RxList<UserModel> _filteredFriends = <UserModel>[].obs; // The friends list after filtering.

  // A StreamSubscription to properly manage the Firestore stream and prevent memory leaks.
  StreamSubscription? _friendshipsSubscription;

  // Public getters to access the reactive state.
  List<FriendshipModel> get friendships => _friendships;
  List<UserModel> get friends => _friends;
  List<UserModel> get filteredFriends => _filteredFriends;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get searchQuery => _searchQuery.value;

  /// Called when the controller is initialized.
  @override
  void onInit() {
    super.onInit();
    _loadFriends();

    // Debounce the search query to avoid excessive filtering on every keystroke.
    // The filter function will only run after the user stops typing for 300ms.
    debounce(
      _searchQuery,
          (_) => _filterFriends(),
      time: const Duration(milliseconds: 300),
    );
  }

  /// Called when the controller is closed.
  @override
  void onClose() {
    // Cancel the stream subscription to prevent memory leaks and unnecessary data fetching.
    _friendshipsSubscription?.cancel();
    super.onClose();
  }

  /// Fetches the list of friendships from Firestore in real-time.
  void _loadFriends() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      // Cancel any previous subscription before creating a new one.
      _friendshipsSubscription?.cancel();

      // Listen to the stream of friendship documents.
      _friendshipsSubscription = _firestoreService
          .getFriendsStream(currentUserId)
          .listen((friendshipList) {
        _friendships.value = friendshipList;
        // After fetching the friendships, load the detailed user data for each friend.
        _loadFriendDetails(currentUserId, friendshipList);
      });
    }
  }

  /// Loads the detailed UserModel for each friend.
  Future<void> _loadFriendDetails(String currentUserId, List<FriendshipModel> friendshipList) async {
    try {
      _isLoading.value = true;
      List<UserModel> friendUsers = [];

      // Use Future.wait to fetch user details in parallel, which is much more efficient.
      final futures = friendshipList.map((friendship) async {
        String friendId = friendship.getOtherUserId(currentUserId);
        return await _firestoreService.getUser(friendId);
      }).toList();

      final results = await Future.wait(futures);

      for (var friend in results) {
        if (friend != null) {
          friendUsers.add(friend);
        }
      }

      _friends.value = friendUsers;
      // Filter the list after loading the friends.
      _filterFriends();
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Filters the friends list based on the search query.
  void _filterFriends() {
    final query = _searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      // If the query is empty, show all friends.
      _filteredFriends.value = _friends;
    } else {
      // Filter the friends list where the display name or email contains the query.
      _filteredFriends.value = _friends.where((friend) {
        return friend.displayName.toLowerCase().contains(query) ||
            friend.email.toLowerCase().contains(query);
      }).toList();
    }
  }

  /// Updates the search query and triggers the filter.
  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  /// Clears the search query and resets the filtered list.
  void clearSearch() {
    _searchQuery.value = '';
  }

  /// Refreshes the friends list manually, often used in a pull-to-refresh action.
  Future<void> refreshFriends() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _loadFriends();
    }
  }

  /// Removes a friend.
  Future<void> removeFriend(UserModel friend) async {
    try {
      // Show a confirmation dialog before proceeding.
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Remove Friend'),
          content: Text(
            'Are you sure you want to remove ${friend.displayName} from your friends?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (result == true) {
        _isLoading.value = true;
        final currentUserId = _authController.user?.uid;

        if (currentUserId != null) {
          // Call the service to remove the friendship.
          await _firestoreService.removeFriendship(currentUserId, friend.id);
          Get.snackbar('Success', '${friend.displayName} removed from friends');
          // The stream listener will automatically update the UI after the change.
        }
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to remove friend: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Blocks a user, which also removes them as a friend.
  Future<void> blockFriend(UserModel friend) async {
    try {
      // Show a confirmation dialog.
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Block User'),
          content: Text(
            'Are you sure you want to block ${friend.displayName}? This will remove them from your friends and prevent them from messaging you.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Block'),
            ),
          ],
        ),
      );

      if (result == true) {
        _isLoading.value = true;
        final currentUserId = _authController.user?.uid;

        if (currentUserId != null) {
          // Call the service to block the user.
          await _firestoreService.blockUser(currentUserId, friend.id);
          Get.snackbar('Success', '${friend.displayName} has been blocked');
          // The stream listener automatically handles the UI update.
        }
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to block user: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Navigates to the chat screen with a selected friend.
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
            'otherUser': friend,
            'isNewChat': true,
          },
        );
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to start chat: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Formats the last seen timestamp of a friend into a user-friendly string.
  String getLastSeenText(UserModel friend) {
    if (friend.isOnline) {
      return 'Online';
    } else {
      final now = DateTime.now();
      final difference = now.difference(friend.lastSeen);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return 'Last seen ${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return 'Last seen ${difference.inDays}d ago';
      } else {
        return 'Last seen ${friend.lastSeen.day}/${friend.lastSeen.month}/${friend.lastSeen.year}';
      }
    }
  }

  /// Navigates to the friend requests screen.
  void openFriendRequests() {
    Get.toNamed(AppRoutes.friendRequests);
  }

  /// Clears the current error message.
  void clearError() {
    _error.value = '';
  }
}