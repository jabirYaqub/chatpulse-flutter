import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/home_controller.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/controllers/main_controller.dart';
import 'package:chat_app_flutter/widgets/chat_list_item.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';

/// GetView that provides the main home screen with chat list functionality
/// Features search, filtering, notifications, and navigation to various chat-related screens
/// Serves as the primary hub for users to access their conversations and start new chats
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for the entire screen
      appBar: _buildAppBar(context, authController),
      body: Column(
        children: [
          // Search bar at the top for finding conversations
          _buildSearchBar(),
          // Dynamic area that shows either search results info or filter chips
          Obx(
                () => controller.isSearching && controller.searchQuery.isNotEmpty
                ? _buildSearchResults()    // Show search result count and clear button
                : _buildQuickFilters(),    // Show filter chips for chat categories
          ),
          // Main content area with pull-to-refresh functionality
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshChats,
              color: AppTheme.primaryColor,
              backgroundColor: Colors.white,
              child: Obx(() {
                // Handle different empty states based on current mode and filters
                if (controller.chats.isEmpty) {
                  if (controller.isSearching &&
                      controller.searchQuery.isNotEmpty) {
                    return _buildNoSearchResults();  // No search matches
                  } else if (controller.activeFilter != 'All') {
                    return _buildNoFilterResults();  // No results for current filter
                  } else {
                    return _buildEmptyState();       // No chats at all
                  }
                }

                // Display the list of chats
                return _buildChatsList();
              }),
            ),
          ),
        ],
      ),
      // Floating action button for starting new chats
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Builds the app bar with profile picture, dynamic title, and action buttons
  /// Features clickable profile picture for navigation and notification badge
  /// @param context - BuildContext for theme access
  /// @param authController - AuthController for user data access
  /// @return PreferredSizeWidget - The configured app bar
  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      AuthController authController,
      ) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimaryColor,
      elevation: 0,
      title: Row(
        children: [
          // Profile picture that's clickable for navigation to profile tab
          Obx(() {
            final user = authController.userModel;
            return GestureDetector(
              onTap: () {
                final mainController = Get.find<MainController>();
                mainController.changeTabIndex(3); // Navigate to profile tab
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: ClipOval(
                  child: user?.photoURL.isNotEmpty == true
                      ? Image.network(
                    user!.photoURL,
                    fit: BoxFit.cover,
                    // Fallback to initials if image fails to load
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultProfileAvatar(user);
                    },
                  )
                      : _buildDefaultProfileAvatar(user),
                ),
              ),
            );
          }),
          const SizedBox(width: 12),
          // Dynamic title that changes based on search state
          Expanded(
            child: Obx(
                  () => Text(
                controller.isSearching ? 'Search Results' : 'Messages',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      actions: [
        // Dynamic action button - clear search or notification bell
        Obx(
              () => controller.isSearching
              ? IconButton(
            onPressed: controller.clearSearch,
            icon: const Icon(Icons.clear_rounded),
            tooltip: 'Clear search',
          )
              : _buildNotificationButton(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Builds the default profile avatar with user's initials
  /// Used as fallback when profile image is unavailable or fails to load
  /// @param user - The user model containing display name
  /// @return Widget - Circular avatar with initials
  Widget _buildDefaultProfileAvatar(dynamic user) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          user?.displayName?.isNotEmpty == true
              ? user!.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Builds the notification button with unread count badge
  /// Shows a red badge with count when there are unread notifications
  /// @return Widget - Notification button with optional badge
  Widget _buildNotificationButton() {
    return Obx(() {
      final unreadNotifications = controller.getUnreadNotificationsCount();

      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            // Main notification button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: controller.openNotifications,
                icon: const Icon(Icons.notifications_outlined, size: 22),
                splashRadius: 20,
              ),
            ),
            // Red badge for unread count (only shown when count > 0)
            if (unreadNotifications > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    // Show "99+" for counts over 99
                    unreadNotifications > 99
                        ? '99+'
                        : unreadNotifications.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  /// Builds the search bar for filtering conversations
  /// Features real-time search with clear button that appears when typing
  /// @return Widget - The search input interface
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          // Real-time search as user types
          onChanged: controller.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey[500],
              size: 20,
            ),
            // Dynamic clear button - only shown when there's text
            suffixIcon: Obx(
                  () => controller.searchQuery.isNotEmpty
                  ? IconButton(
                onPressed: controller.clearSearch,
                icon: Icon(
                  Icons.clear_rounded,
                  color: Colors.grey[500],
                  size: 18,
                ),
              )
                  : const SizedBox.shrink(),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the horizontal scrolling filter chips for chat categories
  /// Shows different categories with dynamic counts from controller
  /// @return Widget - Horizontal scrollable filter interface
  Widget _buildQuickFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All conversations filter
            Obx(
                  () => _buildFilterChip(
                'All',
                    () => controller.setFilter('All'),
                controller.activeFilter == 'All',
              ),
            ),
            const SizedBox(width: 8),
            // Unread conversations filter with dynamic count
            Obx(
                  () => _buildFilterChip(
                'Unread (${controller.getUnreadCount()})',
                    () => controller.setFilter('Unread'),
                controller.activeFilter == 'Unread',
              ),
            ),
            const SizedBox(width: 8),
            // Recent conversations filter with dynamic count
            Obx(
                  () => _buildFilterChip(
                'Recent (${controller.getRecentCount()})',
                    () => controller.setFilter('Recent'),
                controller.activeFilter == 'Recent',
              ),
            ),
            const SizedBox(width: 8),
            // Active conversations filter with dynamic count
            Obx(
                  () => _buildFilterChip(
                'Active (${controller.getActiveCount()})',
                    () => controller.setFilter('Active'),
                controller.activeFilter == 'Active',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds individual filter chip with active/inactive styling
  /// @param label - The text to display on the chip
  /// @param onTap - Callback when chip is tapped
  /// @param isSelected - Whether this chip is currently active
  /// @return Widget - Styled filter chip
  Widget _buildFilterChip(String label, VoidCallback onTap, bool isSelected) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Active filter gets primary color, inactive gets gray
          color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            // White text on active, gray on inactive
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Builds the search results header showing result count and clear option
  /// Displayed when user is actively searching
  /// @return Widget - Search results information bar
  Widget _buildSearchResults() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Dynamic result count text
          Obx(
                () => Text(
              'Found ${controller.filteredChats.length} result${controller.filteredChats.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ),
          const Spacer(),
          // Clear search button
          TextButton(
            onPressed: controller.clearSearch,
            child: Text(
              'Clear',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds empty state for when search returns no results
  /// Shows search-specific messaging and current search query
  /// @return Widget - No search results display
  Widget _buildNoSearchResults() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No conversations found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              // Show current search query
              Obx(
                    () => Text(
                  'No results for "${controller.searchQuery}"',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds empty state for when current filter has no results
  /// Shows filter-specific messaging and option to clear filter
  /// @return Widget - No filter results display
  Widget _buildNoFilterResults() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFilterIcon(controller.activeFilter),
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No ${controller.activeFilter.toLowerCase()} conversations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getFilterEmptyMessage(controller.activeFilter),
                style: TextStyle(color: AppTheme.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Button to clear filter and show all conversations
              ElevatedButton(
                onPressed: () => controller.setFilter('All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Show All Conversations'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns appropriate icon for each filter type
  /// @param filter - The filter name
  /// @return IconData - Matching icon for the filter
  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Unread':
        return Icons.mark_email_unread_outlined;
      case 'Recent':
        return Icons.schedule_outlined;
      case 'Active':
        return Icons.trending_up_outlined;
      default:
        return Icons.filter_list_outlined;
    }
  }

  /// Returns appropriate empty message for each filter type
  /// @param filter - The filter name
  /// @return String - User-friendly message for empty filter
  String _getFilterEmptyMessage(String filter) {
    switch (filter) {
      case 'Unread':
        return 'All your conversations are up to date!';
      case 'Recent':
        return 'No conversations from the last 3 days';
      case 'Active':
        return 'No conversations from the last week';
      default:
        return 'No conversations found';
    }
  }

  /// Builds the main chats list with header and animated items
  /// Features dividers between items and responsive padding
  /// @return Widget - The complete chats list interface
  Widget _buildChatsList() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header section (only shown when not searching)
          if (!controller.isSearching || controller.searchQuery.isEmpty)
            _buildChatsHeader(),
          // Scrollable list of chat items
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: controller.isSearching ? 16 : 8,
              ),
              itemCount: controller.chats.length,
              // Dividers between chat items
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey[200], indent: 72),
              itemBuilder: (context, index) {
                final chat = controller.chats[index];
                final otherUser = controller.getOtherUser(chat);

                // Skip rendering if other user data is unavailable
                if (otherUser == null) {
                  return const SizedBox.shrink();
                }

                // Animated container for smooth transitions
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: ChatListItem(
                    chat: chat,
                    otherUser: otherUser,
                    lastMessageTime: controller.formatLastMessageTime(
                      chat.lastMessageTime,
                    ),
                    onTap: () => controller.openChat(chat),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header section above the chats list
  /// Shows current filter title and clear filter option
  /// @return Widget - Chats list header
  Widget _buildChatsHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dynamic title based on current filter
          Obx(() {
            String title = 'Recent Chats';
            switch (controller.activeFilter) {
              case 'Unread':
                title = 'Unread Messages';
                break;
              case 'Recent':
                title = 'Recent Chats';
                break;
              case 'Active':
                title = 'Active Conversations';
                break;
            }
            return Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            );
          }),
          Row(
            children: [
              // Clear filter button (only shown when filter is active)
              if (controller.activeFilter != 'All')
                TextButton(
                  onPressed: controller.clearAllFilters,
                  child: Text(
                    'Clear Filter',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the floating action button for starting new chats
  /// Features shadow styling and navigation to friends list
  /// @return Widget - Styled floating action button
  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: controller.openFriends,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.chat_rounded, size: 20),
        label: const Text(
          'New Chat',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  /// Builds the main empty state when user has no conversations
  /// Features onboarding messaging and action buttons for getting started
  /// @return Widget - Complete empty state interface
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      // Allow pull-to-refresh even when empty
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(Get.context!).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEmptyStateIcon(),    // Large decorative icon
                const SizedBox(height: 24),
                _buildEmptyStateText(),    // Heading and description
                const SizedBox(height: 32),
                _buildEmptyStateActions(), // Action buttons
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the decorative icon for the empty state
  /// Features gradient background and chat bubble icon
  /// @return Widget - Styled empty state icon
  Widget _buildEmptyStateIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(70),
      ),
      child: Icon(
        Icons.chat_bubble_outline_rounded,
        size: 64,
        color: AppTheme.primaryColor,
      ),
    );
  }

  /// Builds the text content for the empty state
  /// Includes main heading and descriptive subtext
  /// @return Widget - Empty state text content
  Widget _buildEmptyStateText() {
    return Column(
      children: [
        Text(
          'No conversations yet',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with friends and start meaningful conversations',
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondaryColor,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the action buttons for the empty state
  /// Primary button for finding people, secondary for viewing friends
  /// @return Widget - Empty state action buttons
  Widget _buildEmptyStateActions() {
    return Column(
      children: [
        // Primary action - Find People (navigates to people search)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final mainController = Get.find<MainController>();
              mainController.changeTabIndex(2); // Navigate to people tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.person_search_rounded),
            label: const Text(
              'Find People',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary action - View Friends (navigates to friends list)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final mainController = Get.find<MainController>();
              mainController.changeTabIndex(1); // Navigate to friends tab
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.people_rounded),
            label: const Text(
              'View Friends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
