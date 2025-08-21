import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/models/chat_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/models/notification_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';

class HomeController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<ChatModel> _allChats = <ChatModel>[].obs;
  final RxList<ChatModel> _filteredChats = <ChatModel>[].obs;
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _isSearching = false.obs;
  final RxString _activeFilter = 'All'.obs;

  // Getters
  List<ChatModel> get chats => _getFilteredChats();
  List<ChatModel> get allChats => _allChats;
  List<ChatModel> get filteredChats => _filteredChats;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  Map<String, UserModel> get users => _users;
  String get searchQuery => _searchQuery.value;
  bool get isSearching => _isSearching.value;
  String get activeFilter => _activeFilter.value;

  @override
  void onInit() {
    super.onInit();
    _loadChats();
    _loadUsers();
    _loadNotifications();
  }

  void _loadChats() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _allChats.bindStream(_firestoreService.getUserChatsStream(currentUserId));

      // Listen to changes in _allChats and update filtered chats
      ever(_allChats, (_) {
        if (_isSearching.value && _searchQuery.value.isNotEmpty) {
          _performSearch(_searchQuery.value);
        }
      });

      // Listen to filter changes
      ever(_activeFilter, (_) {
        if (_searchQuery.value.isNotEmpty) {
          _performSearch(_searchQuery.value);
        }
      });
    }
  }

  void _loadUsers() {
    _users.bindStream(
      _firestoreService.getAllUsersStream().map((userList) {
        Map<String, UserModel> userMap = {};
        for (var user in userList) {
          userMap[user.id] = user;
        }
        return userMap;
      }),
    );
  }

  void _loadNotifications() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _notifications.bindStream(
        _firestoreService.getNotificationsStream(currentUserId),
      );
    }
  }

  UserModel? getOtherUser(ChatModel chat) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      final otherUserId = chat.getOtherParticipant(currentUserId);
      return _users[otherUserId];
    }
    return null;
  }

  String formatLastMessageTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      // Use 12-hour format
      int hour = time.hour;
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString()}:${time.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  // Get filtered chats based on active filter and search
  List<ChatModel> _getFilteredChats() {
    List<ChatModel> baseList = _isSearching.value ? _filteredChats : _allChats;

    switch (_activeFilter.value) {
      case 'Unread':
        return _applyUnreadFilter(baseList);
      case 'Recent':
        return _applyRecentFilter(baseList);
      case 'Active':
        return _applyActiveFilter(baseList);
      case 'All':
      default:
        return baseList;
    }
  }

  List<ChatModel> _applyUnreadFilter(List<ChatModel> chats) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return [];

    return chats.where((chat) => chat.getUnreadCount(currentUserId) > 0).toList();
  }

  List<ChatModel> _applyRecentFilter(List<ChatModel> chats) {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));

    return chats.where((chat) {
      if (chat.lastMessageTime == null) return false;
      return chat.lastMessageTime!.isAfter(threeDaysAgo);
    }).toList();
  }

  List<ChatModel> _applyActiveFilter(List<ChatModel> chats) {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    return chats.where((chat) {
      if (chat.lastMessageTime == null) return false;
      return chat.lastMessageTime!.isAfter(oneWeekAgo);
    }).toList();
  }

  // Filter management
  void setFilter(String filterType) {
    _activeFilter.value = filterType;

    if (filterType == 'All') {
      // If switching to 'All' and not searching, clear search state
      if (_searchQuery.value.isEmpty) {
        _isSearching.value = false;
        _filteredChats.clear();
      }
    }
  }

  void clearAllFilters() {
    _activeFilter.value = 'All';
    _clearSearch();
  }
  // Search functionality
  void onSearchChanged(String query) {
    _searchQuery.value = query;

    if (query.isEmpty) {
      _clearSearch();
    } else {
      _isSearching.value = true;
      _performSearch(query);
    }
  }

  void _performSearch(String query) {
    final lowercaseQuery = query.toLowerCase().trim();

    _filteredChats.value = _allChats.where((chat) {
      // Get the other user in the chat
      final otherUser = getOtherUser(chat);
      if (otherUser == null) return false;

      // Search criteria
      final displayNameMatch = otherUser.displayName
          ?.toLowerCase()
          .contains(lowercaseQuery) ?? false;

      final emailMatch = otherUser.email
          ?.toLowerCase()
          .contains(lowercaseQuery) ?? false;

      final lastMessageMatch = chat.lastMessage
          ?.toLowerCase()
          .contains(lowercaseQuery) ?? false;

      // You can add more search criteria here
      // For example, searching in chat messages (would require additional data)

      return displayNameMatch || emailMatch || lastMessageMatch;
    }).toList();

    // Sort filtered results by relevance (optional)
    _sortSearchResults(lowercaseQuery);
  }

  void _sortSearchResults(String query) {
    _filteredChats.sort((a, b) {
      final userA = getOtherUser(a);
      final userB = getOtherUser(b);

      if (userA == null || userB == null) return 0;

      // Prioritize exact matches in display name
      final exactMatchA = userA.displayName?.toLowerCase().startsWith(query) ?? false;
      final exactMatchB = userB.displayName?.toLowerCase().startsWith(query) ?? false;

      if (exactMatchA && !exactMatchB) return -1;
      if (!exactMatchA && exactMatchB) return 1;

      // Then sort by last message time (most recent first)
      return (b.lastMessageTime ?? DateTime(0))
          .compareTo(a.lastMessageTime ?? DateTime(0));
    });
  }

  void _clearSearch() {
    _isSearching.value = false;
    _filteredChats.clear();
  }

  void clearSearch() {
    _searchQuery.value = '';
    _clearSearch();
    // Keep the current filter active
  }

  // Advanced search methods
  void searchByUserName(String name) {
    onSearchChanged(name);
  }

  void searchByLastMessage(String message) {
    onSearchChanged(message);
  }

  List<ChatModel> getUnreadChats() {
    return _applyUnreadFilter(_allChats);
  }

  List<ChatModel> getActiveChats() {
    return _applyActiveFilter(_allChats);
  }

  List<ChatModel> getRecentChats({int limit = 10}) {
    final recentChats = _applyRecentFilter(_allChats);
    final sortedChats = List<ChatModel>.from(recentChats);
    sortedChats.sort((a, b) =>
        (b.lastMessageTime ?? DateTime(0))
            .compareTo(a.lastMessageTime ?? DateTime(0)));

    return sortedChats.take(limit).toList();
  }

  // Get count for each filter
  int getUnreadCount() {
    return getUnreadChats().length;
  }

  int getRecentCount() {
    return _applyRecentFilter(_allChats).length;
  }

  int getActiveCount() {
    return getActiveChats().length;
  }

  // Search suggestions
  List<String> getSearchSuggestions() {
    final suggestions = <String>[];

    for (var chat in _allChats) {
      final otherUser = getOtherUser(chat);
      if (otherUser?.displayName != null) {
        suggestions.add(otherUser!.displayName!);
      }
    }

    return suggestions.toSet().toList(); // Remove duplicates
  }

  // Existing methods
  void openChat(ChatModel chat) {
    final otherUser = getOtherUser(chat);
    if (otherUser != null) {
      // Mark chat as read before opening
      markChatAsRead(chat.id, _authController.user?.uid ?? '');

      Get.toNamed(
        AppRoutes.chat,
        arguments: {'chatId': chat.id, 'otherUser': otherUser},
      );
    }
  }

  // NEW METHOD: Mark chat as read when tapped
  Future<void> markChatAsRead(String chatId, String currentUserId) async {
    try {
      if (currentUserId.isEmpty || chatId.isEmpty) return;

      print('🔄 HomeController: Marking chat as read - ChatID: $chatId, UserID: $currentUserId');

      // Reset unread count in Firestore
      await _firestoreService.resetUnreadCount(chatId, currentUserId);

      // Find and update the local chat object
      final chatIndex = _allChats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        final chat = _allChats[chatIndex];

        // Create updated chat with unread count reset
        final updatedChat = ChatModel(
          id: chat.id,
          participants: chat.participants,
          lastMessage: chat.lastMessage,
          lastMessageTime: chat.lastMessageTime,
          lastMessageSenderId: chat.lastMessageSenderId,
          unreadCount: Map<String, int>.from(chat.unreadCount)
            ..[currentUserId] = 0, // Reset unread count for current user
          createdAt: chat.createdAt,
          updatedAt: chat.updatedAt,
        );

        _allChats[chatIndex] = updatedChat;
        _allChats.refresh();

        print('✅ HomeController: Local chat unread count reset');
      }

    } catch (e) {
      print('❌ HomeController: Error marking chat as read: $e');
    }
  }

  // Updated to pass back button flag
  void openFriends() {
    Get.toNamed(AppRoutes.friends, arguments: {'showBackButton': true});
  }

  void openNotifications() {
    Get.toNamed(AppRoutes.notifications);
  }

  Future<void> refreshChats() async {
    _isLoading.value = true;
    try {
      // The stream will automatically refresh, but we can add manual refresh logic here if needed
      await Future.delayed(const Duration(seconds: 1));

      // If currently searching, re-perform the search with fresh data
      if (_isSearching.value && _searchQuery.value.isNotEmpty) {
        _performSearch(_searchQuery.value);
      }
    } finally {
      _isLoading.value = false;
    }
  }

  int getTotalUnreadCount() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return 0;

    int total = 0;
    for (var chat in _allChats) {
      total += chat.getUnreadCount(currentUserId);
    }
    return total;
  }

  int getUnreadNotificationsCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  Future<void> deleteChat(ChatModel chat) async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;

      final otherUser = getOtherUser(chat);
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Chat'),
          content: Text('Are you sure you want to delete the chat with ${otherUser?.displayName ?? 'this user'}?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (result == true) {
        _isLoading.value = true;
        await _firestoreService.deleteChatForUser(chat.id, currentUserId);
        Get.snackbar('Success', 'Chat deleted');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to delete chat: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _error.value = '';
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}