import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/models/chat_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/models/notification_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';

/// HomeController manages the main chat list screen functionality.
/// This is one of the most complex controllers as it handles multiple data streams,
/// advanced filtering, search functionality, and coordination with other screens.
///
/// This controller is responsible for:
/// - Real-time streaming of user's chat conversations
/// - Advanced search functionality across chats, users, and messages
/// - Multiple filter types (All, Unread, Recent, Active)
/// - User data caching for efficient profile information access
/// - Notification management and unread counts
/// - Chat deletion and read status management
/// - Navigation to individual chats with proper state updates
/// - Integration with ChatController for seamless data synchronization
class HomeController extends GetxController {

  // ==================== DEPENDENCIES ====================

  /// Service dependencies for data access and authentication
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  // ==================== REACTIVE STATE VARIABLES ====================

  /// Core data streams and collections
  /// Complete list of all user's chats from Firestore
  final RxList<ChatModel> _allChats = <ChatModel>[].obs;

  /// Filtered chats based on search query (subset of _allChats)
  final RxList<ChatModel> _filteredChats = <ChatModel>[].obs;

  /// User's notifications stream
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;

  /// Global loading state for operations like refresh and delete
  final RxBool _isLoading = false.obs;

  /// Error messages for user feedback
  final RxString _error = ''.obs;

  /// Cached user data for efficient profile lookup (userId -> UserModel)
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;

  /// Search and filtering state
  /// Current search query entered by user
  final RxString _searchQuery = ''.obs;

  /// Whether search mode is active (determines which chat list to show)
  final RxBool _isSearching = false.obs;

  /// Current filter type: 'All', 'Unread', 'Recent', 'Active'
  final RxString _activeFilter = 'All'.obs;

  // ==================== PUBLIC GETTERS ====================

  /// Public getters providing controlled access to reactive state
  /// Returns the appropriate chat list based on current filter and search state
  List<ChatModel> get chats => _getFilteredChats();

  /// Raw unfiltered chat list
  List<ChatModel> get allChats => _allChats;

  /// Search result chats
  List<ChatModel> get filteredChats => _filteredChats;

  /// User's notifications
  List<NotificationModel> get notifications => _notifications;

  /// Loading state indicator
  bool get isLoading => _isLoading.value;

  /// Current error message
  String get error => _error.value;

  /// Cached user data map
  Map<String, UserModel> get users => _users;

  /// Current search query
  String get searchQuery => _searchQuery.value;

  /// Whether search is active
  bool get isSearching => _isSearching.value;

  /// Current filter type
  String get activeFilter => _activeFilter.value;

  // ==================== LIFECYCLE METHODS ====================

  /// Controller initialization - sets up all data streams
  @override
  void onInit() {
    super.onInit();
    // Initialize all data streams for real-time updates
    _loadChats();
    _loadUsers();
    _loadNotifications();
  }

  /// Controller cleanup
  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }

  // ==================== DATA LOADING AND STREAMING ====================

  /// Sets up real-time chat data streaming with reactive filters
  void _loadChats() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      // Bind to real-time chat stream from Firestore
      _allChats.bindStream(_firestoreService.getUserChatsStream(currentUserId));

      // Listen to changes in _allChats and update filtered chats
      // This ensures search results stay current when new chats arrive
      ever(_allChats, (_) {
        if (_isSearching.value && _searchQuery.value.isNotEmpty) {
          _performSearch(_searchQuery.value);
        }
      });

      // Listen to filter changes and update search results accordingly
      ever(_activeFilter, (_) {
        if (_searchQuery.value.isNotEmpty) {
          _performSearch(_searchQuery.value);
        }
      });
    }
  }

  /// Sets up user data caching stream for efficient profile access
  void _loadUsers() {
    // Transform user list into map for O(1) lookup performance
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

  /// Sets up notifications stream
  void _loadNotifications() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _notifications.bindStream(
        _firestoreService.getNotificationsStream(currentUserId),
      );
    }
  }

  // ==================== USER DATA ACCESS ====================

  /// Retrieves the other participant's user data for a given chat
  /// Returns null if user not found or current user cannot be determined
  UserModel? getOtherUser(ChatModel chat) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      final otherUserId = chat.getOtherParticipant(currentUserId);
      return _users[otherUserId];
    }
    return null;
  }

  // ==================== TIME FORMATTING ====================

  /// Formats message timestamps into user-friendly strings
  /// Provides progressive detail based on message age
  String formatLastMessageTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      // Very recent messages
      return 'Just now';
    } else if (difference.inHours < 1) {
      // Messages within the hour
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      // Messages from today - Use 12-hour format for clarity
      int hour = time.hour;
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString()}:${time.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays < 7) {
      // Messages from this week
      return '${difference.inDays}d ago';
    } else {
      // Older messages - show full date
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  // ==================== CHAT FILTERING SYSTEM ====================

  /// Returns the appropriate chat list based on current filter and search state
  /// This is the main method that determines what chats the UI displays
  List<ChatModel> _getFilteredChats() {
    // Use search results if searching, otherwise use all chats
    List<ChatModel> baseList = _isSearching.value ? _filteredChats : _allChats;

    // Apply the active filter to the base list
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

  /// Filters chats to show only those with unread messages
  List<ChatModel> _applyUnreadFilter(List<ChatModel> chats) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return [];

    return chats.where((chat) => chat.getUnreadCount(currentUserId) > 0).toList();
  }

  /// Filters chats to show only those with messages in the last 3 days
  List<ChatModel> _applyRecentFilter(List<ChatModel> chats) {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));

    return chats.where((chat) {
      if (chat.lastMessageTime == null) return false;
      return chat.lastMessageTime!.isAfter(threeDaysAgo);
    }).toList();
  }

  /// Filters chats to show only those with activity in the last week
  List<ChatModel> _applyActiveFilter(List<ChatModel> chats) {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    return chats.where((chat) {
      if (chat.lastMessageTime == null) return false;
      return chat.lastMessageTime!.isAfter(oneWeekAgo);
    }).toList();
  }

  // ==================== FILTER MANAGEMENT ====================

  /// Updates the active filter and manages search state accordingly
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

  /// Resets all filters and search to show all chats
  void clearAllFilters() {
    _activeFilter.value = 'All';
    _clearSearch();
  }

  // ==================== SEARCH FUNCTIONALITY ====================

  /// Handles search query changes with automatic clearing
  void onSearchChanged(String query) {
    _searchQuery.value = query;

    if (query.isEmpty) {
      // Clear search when query is empty
      _clearSearch();
    } else {
      // Activate search mode and perform search
      _isSearching.value = true;
      _performSearch(query);
    }
  }

  /// Performs the actual search across multiple chat attributes
  void _performSearch(String query) {
    final lowercaseQuery = query.toLowerCase().trim();

    // Search across multiple criteria for comprehensive results
    _filteredChats.value = _allChats.where((chat) {
      // Get the other user in the chat for profile-based searching
      final otherUser = getOtherUser(chat);
      if (otherUser == null) return false;

      // Search criteria - multiple ways to match a chat
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

      // Return true if any search criteria matches
      return displayNameMatch || emailMatch || lastMessageMatch;
    }).toList();

    // Sort filtered results by relevance for better user experience
    _sortSearchResults(lowercaseQuery);
  }

  /// Sorts search results by relevance and recency
  void _sortSearchResults(String query) {
    _filteredChats.sort((a, b) {
      final userA = getOtherUser(a);
      final userB = getOtherUser(b);

      if (userA == null || userB == null) return 0;

      // Prioritize exact matches in display name (most relevant first)
      final exactMatchA = userA.displayName?.toLowerCase().startsWith(query) ?? false;
      final exactMatchB = userB.displayName?.toLowerCase().startsWith(query) ?? false;

      if (exactMatchA && !exactMatchB) return -1;
      if (!exactMatchA && exactMatchB) return 1;

      // Then sort by last message time (most recent first)
      return (b.lastMessageTime ?? DateTime(0))
          .compareTo(a.lastMessageTime ?? DateTime(0));
    });
  }

  /// Internal method to clear search state
  void _clearSearch() {
    _isSearching.value = false;
    _filteredChats.clear();
  }

  /// Public method to clear search while keeping filters active
  void clearSearch() {
    _searchQuery.value = '';
    _clearSearch();
    // Keep the current filter active
  }

  // ==================== SPECIALIZED SEARCH METHODS ====================

  /// Search specifically by user name
  void searchByUserName(String name) {
    onSearchChanged(name);
  }

  /// Search specifically by last message content
  void searchByLastMessage(String message) {
    onSearchChanged(message);
  }

  // ==================== FILTER RESULT METHODS ====================

  /// Get chats with unread messages
  List<ChatModel> getUnreadChats() {
    return _applyUnreadFilter(_allChats);
  }

  /// Get chats with recent activity (last week)
  List<ChatModel> getActiveChats() {
    return _applyActiveFilter(_allChats);
  }

  /// Get chats with messages in the last 3 days, with optional limit
  List<ChatModel> getRecentChats({int limit = 10}) {
    final recentChats = _applyRecentFilter(_allChats);
    final sortedChats = List<ChatModel>.from(recentChats);
    // Sort by most recent first
    sortedChats.sort((a, b) =>
        (b.lastMessageTime ?? DateTime(0))
            .compareTo(a.lastMessageTime ?? DateTime(0)));

    return sortedChats.take(limit).toList();
  }

  // ==================== COUNT METHODS FOR UI BADGES ====================

  /// Get count of chats with unread messages for UI badges
  int getUnreadCount() {
    return getUnreadChats().length;
  }

  /// Get count of recent chats for UI badges
  int getRecentCount() {
    return _applyRecentFilter(_allChats).length;
  }

  /// Get count of active chats for UI badges
  int getActiveCount() {
    return getActiveChats().length;
  }

  // ==================== SEARCH SUGGESTIONS ====================

  /// Generate search suggestions based on existing chats
  List<String> getSearchSuggestions() {
    final suggestions = <String>[];

    // Collect display names from all chat participants
    for (var chat in _allChats) {
      final otherUser = getOtherUser(chat);
      if (otherUser?.displayName != null) {
        suggestions.add(otherUser!.displayName!);
      }
    }

    // Remove duplicates and return
    return suggestions.toSet().toList();
  }

  // ==================== CHAT NAVIGATION AND MANAGEMENT ====================

  /// Opens a specific chat and marks it as read
  void openChat(ChatModel chat) {
    final otherUser = getOtherUser(chat);
    if (otherUser != null) {
      // Mark chat as read before opening to update unread counts
      markChatAsRead(chat.id, _authController.user?.uid ?? '');

      // Navigate to chat screen with required data
      Get.toNamed(
        AppRoutes.chat,
        arguments: {'chatId': chat.id, 'otherUser': otherUser},
      );
    }
  }

  /// Marks a chat as read both locally and in Firestore
  /// This method is called by ChatController to maintain consistency
  Future<void> markChatAsRead(String chatId, String currentUserId) async {
    try {
      if (currentUserId.isEmpty || chatId.isEmpty) return;

      print('🔄 HomeController: Marking chat as read - ChatID: $chatId, UserID: $currentUserId');

      // Reset unread count in Firestore
      await _firestoreService.resetUnreadCount(chatId, currentUserId);

      // Find and update the local chat object for immediate UI update
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

        // Update local state and trigger UI refresh
        _allChats[chatIndex] = updatedChat;
        _allChats.refresh();

        print('✅ HomeController: Local chat unread count reset');
      }

    } catch (e) {
      print('❌ HomeController: Error marking chat as read: $e');
    }
  }

  // ==================== NAVIGATION METHODS ====================

  /// Navigate to friends screen with back button enabled
  void openFriends() {
    Get.toNamed(AppRoutes.friends, arguments: {'showBackButton': true});
  }

  /// Navigate to notifications screen
  void openNotifications() {
    Get.toNamed(AppRoutes.notifications);
  }

  // ==================== REFRESH AND UTILITY METHODS ====================

  /// Manual refresh for pull-to-refresh functionality
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

  /// Calculate total unread messages across all chats for app badge
  int getTotalUnreadCount() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return 0;

    int total = 0;
    for (var chat in _allChats) {
      total += chat.getUnreadCount(currentUserId);
    }
    return total;
  }

  /// Get count of unread notifications for UI badge
  int getUnreadNotificationsCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  /// Delete a chat with confirmation dialog
  Future<void> deleteChat(ChatModel chat) async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;

      final otherUser = getOtherUser(chat);
      // Show confirmation dialog to prevent accidental deletion
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

      // Proceed with deletion only if confirmed
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

  /// Clear current error message
  void clearError() {
    _error.value = '';
  }
}
