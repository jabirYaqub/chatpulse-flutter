import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/models/friend_request_model.dart';
import 'package:chat_app_flutter/models/friendship_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';

enum UserRelationshipStatus {
  none,
  friendRequestSent,
  friendRequestReceived,
  friends,
  blocked,
}

class UsersListController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = const Uuid();

  final RxList<UserModel> _users = <UserModel>[].obs;
  final RxList<UserModel> _filteredUsers = <UserModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxString _searchQuery = ''.obs;
  final RxMap<String, UserRelationshipStatus> _userRelationships =
      <String, UserRelationshipStatus>{}.obs;
  final RxList<FriendRequestModel> _sentRequests = <FriendRequestModel>[].obs;
  final RxList<FriendRequestModel> _receivedRequests =
      <FriendRequestModel>[].obs;
  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs;

  List<UserModel> get users => _users;
  List<UserModel> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get searchQuery => _searchQuery.value;
  Map<String, UserRelationshipStatus> get userRelationships =>
      _userRelationships;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
    _loadRelationships();

    // Listen to search query changes
    debounce(
      _searchQuery,
          (_) => _filterUsers(),
      time: const Duration(milliseconds: 300),
    );
  }

  void _loadUsers() {
    _users.bindStream(_firestoreService.getAllUsersStream());

    // Filter out current user and update filtered list
    ever(_users, (List<UserModel> userList) {
      final currentUserId = _authController.user?.uid;
      final otherUsers = userList
          .where((user) => user.id != currentUserId)
          .toList();

      if (_searchQuery.value.isEmpty) {
        _filteredUsers.value = otherUsers;
      } else {
        _filterUsers();
      }
    });
  }

  void _loadRelationships() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      // Load sent friend requests
      _sentRequests.bindStream(
        _firestoreService.getSentFriendRequestsStream(currentUserId),
      );

      // Load received friend requests
      _receivedRequests.bindStream(
        _firestoreService.getFriendRequestsStream(currentUserId),
      );

      // Load friendships
      _friendships.bindStream(
        _firestoreService.getFriendsStream(currentUserId),
      );

      // Update relationship status when any of these change
      ever(_sentRequests, (_) => _updateAllRelationshipStatuses());
      ever(_receivedRequests, (_) => _updateAllRelationshipStatuses());
      ever(_friendships, (_) => _updateAllRelationshipStatuses());

      // Initial load
      ever(_users, (_) => _updateAllRelationshipStatuses());
    }
  }

  void _updateAllRelationshipStatuses() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    for (var user in _users) {
      if (user.id != currentUserId) {
        final status = _calculateUserRelationshipStatus(user.id);
        _userRelationships[user.id] = status;
      }
    }
  }

  UserRelationshipStatus _calculateUserRelationshipStatus(String userId) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return UserRelationshipStatus.none;

    // Check if they are friends
    final friendship = _friendships.firstWhereOrNull(
          (f) =>
      (f.user1Id == currentUserId && f.user2Id == userId) ||
          (f.user1Id == userId && f.user2Id == currentUserId),
    );

    if (friendship != null) {
      if (friendship.isBlocked) {
        return UserRelationshipStatus.blocked;
      } else {
        return UserRelationshipStatus.friends;
      }
    }

    // Check for sent friend requests
    final sentRequest = _sentRequests.firstWhereOrNull(
          (r) => r.receiverId == userId && r.status == FriendRequestStatus.pending,
    );
    if (sentRequest != null) {
      return UserRelationshipStatus.friendRequestSent;
    }

    // Check for received friend requests
    final receivedRequest = _receivedRequests.firstWhereOrNull(
          (r) => r.senderId == userId && r.status == FriendRequestStatus.pending,
    );
    if (receivedRequest != null) {
      return UserRelationshipStatus.friendRequestReceived;
    }

    return UserRelationshipStatus.none;
  }

  void _filterUsers() {
    final currentUserId = _authController.user?.uid;
    final query = _searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      _filteredUsers.value = _users
          .where((user) => user.id != currentUserId)
          .toList();
    } else {
      _filteredUsers.value = _users.where((user) {
        return user.id != currentUserId &&
            (user.displayName.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query));
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void clearSearch() {
    _searchQuery.value = '';
  }

  Future<void> sendFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = FriendRequestModel(
          id: _uuid.v4(),
          senderId: currentUserId,
          receiverId: user.id,
          createdAt: DateTime.now(),
        );

        // Immediately update the UI
        _userRelationships[user.id] = UserRelationshipStatus.friendRequestSent;

        await _firestoreService.sendFriendRequest(request);
        Get.snackbar('Success', 'Friend request sent to ${user.displayName}');
      }
    } catch (e) {
      // Revert the UI change on error
      _userRelationships[user.id] = UserRelationshipStatus.none;
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to send friend request: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> cancelFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _sentRequests.firstWhereOrNull(
              (r) =>
          r.receiverId == user.id &&
              r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          // Immediately update the UI
          _userRelationships[user.id] = UserRelationshipStatus.none;

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

  Future<void> acceptFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _receivedRequests.firstWhereOrNull(
              (r) =>
          r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          // Immediately update the UI
          _userRelationships[user.id] = UserRelationshipStatus.friends;

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

  Future<void> declineFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _receivedRequests.firstWhereOrNull(
              (r) =>
          r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          // Immediately update the UI
          _userRelationships[user.id] = UserRelationshipStatus.none;

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

  Future<void> startChat(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        // Check if they are friends first
        final relationship =
            _userRelationships[user.id] ?? UserRelationshipStatus.none;
        if (relationship != UserRelationshipStatus.friends) {
          Get.snackbar(
            'Info',
            'You can only chat with friends. Send a friend request first.',
          );
          return;
        }

        final chatId = await _firestoreService.createOrGetChat(
          currentUserId,
          user.id,
        );

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

  UserRelationshipStatus getUserRelationshipStatus(String userId) {
    return _userRelationships[userId] ?? UserRelationshipStatus.none;
  }

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

  IconData getRelationshipButtonIcon(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none:
        return Icons.person_add;
      case UserRelationshipStatus.friendRequestSent:
        return Icons.access_time;
      case UserRelationshipStatus.friendRequestReceived:
        return Icons.check;
      case UserRelationshipStatus.friends:
        return Icons.chat_bubble_outline;
      case UserRelationshipStatus.blocked:
        return Icons.block;
    }
  }

  Color getRelationshipButtonColor(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none:
        return Colors.blue;
      case UserRelationshipStatus.friendRequestSent:
        return Colors.orange;
      case UserRelationshipStatus.friendRequestReceived:
        return Colors.green;
      case UserRelationshipStatus.friends:
        return Colors.blue;
      case UserRelationshipStatus.blocked:
        return Colors.red;
    }
  }

  void handleRelationshipAction(UserModel user) {
    final status = getUserRelationshipStatus(user.id);

    switch (status) {
      case UserRelationshipStatus.none:
        sendFriendRequest(user);
        break;
      case UserRelationshipStatus.friendRequestSent:
      // Do nothing, request already sent
        Get.snackbar('Info', 'Friend request already sent');
        break;
      case UserRelationshipStatus.friendRequestReceived:
        acceptFriendRequest(user);
        break;
      case UserRelationshipStatus.friends:
        startChat(user);
        break;
      case UserRelationshipStatus.blocked:
        Get.snackbar('Info', 'This user is blocked');
        break;
    }
  }

  String getLastSeenText(UserModel user) {
    if (user.isOnline) {
      return 'Online';
    } else {
      final now = DateTime.now();
      final difference = now.difference(user.lastSeen);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return 'Last seen ${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return 'Last seen ${difference.inDays}d ago';
      } else {
        return 'Last seen ${user.lastSeen.day}/${user.lastSeen.month}/${user.lastSeen.year}';
      }
    }
  }

  void clearError() {
    _error.value = '';
  }
}
