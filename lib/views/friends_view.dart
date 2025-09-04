import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/friends_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/widgets/friend_list_item.dart';

/// GetView that displays the user's friends list with search and management functionality
/// Features pull-to-refresh, search filtering, and actions like chat, remove, and block
/// Can be accessed from navigation drawer or as a chat selection screen
class FriendsView extends GetView<FriendsController> {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if we came from New Chat button (navigation from home)
    // This determines whether to show a back button in the app bar
    final bool showBackButton = Get.arguments?['showBackButton'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        // Conditionally show back button based on navigation context
        leading: showBackButton
            ? IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        )
            : const SizedBox(), // Empty widget when no back button needed
        actions: [
          // Friend requests access button in the app bar
          IconButton(
            onPressed: controller.openFriendRequests,
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Friend Requests',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar for filtering friends list
          _buildSearchBar(),
          // Main content area with pull-to-refresh functionality
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshFriends,
              child: Obx(() {
                // Show loading indicator only when initially loading and no cached data
                if (controller.isLoading && controller.friends.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Show empty state when no friends match current filter/search
                if (controller.filteredFriends.isEmpty) {
                  return _buildEmptyState();
                }

                // Build scrollable list of friends
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.filteredFriends.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final friend = controller.filteredFriends[index];
                    return FriendListItem(
                      friend: friend,
                      lastSeenText: controller.getLastSeenText(friend),
                      // Action callbacks for friend interactions
                      onTap: () => controller.startChat(friend),      // Start chat
                      onRemove: () => controller.removeFriend(friend), // Remove friend
                      onBlock: () => controller.blockFriend(friend),   // Block friend
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the search bar with real-time filtering and clear functionality
  /// Features rounded input styling and dynamic clear button visibility
  /// @return Widget - The search bar interface
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: TextField(
        // Real-time search as user types
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search friends...',
          prefixIcon: const Icon(Icons.search),
          // Dynamic suffix icon - show clear button only when text exists
          suffixIcon: Obx(() {
            return controller.searchQuery.isNotEmpty
                ? IconButton(
              onPressed: controller.clearSearch,
              icon: const Icon(Icons.clear),
            )
                : const SizedBox.shrink(); // Hide when search is empty
          }),
          // Custom border styling for different states
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppTheme.cardColor,
        ),
      ),
    );
  }

  /// Builds the empty state display with context-aware messaging
  /// Shows different content based on whether user is searching or has no friends
  /// Includes action button to navigate to friend requests when appropriate
  /// @return Widget - The empty state interface
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      // Always allow scrolling for pull-to-refresh even when empty
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        // Set minimum height to center content vertically
        height: MediaQuery.of(Get.context!).size.height * 0.6,
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with circular background
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.people_outline,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // Dynamic heading text based on search state
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'No friends found'         // When searching but no results
                  : 'No friends yet',          // When no friends at all
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            // Dynamic message text based on search state
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'Try a different search term'        // Search guidance
                  : 'Add friends to start chatting with them', // Onboarding guidance
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            // Show action button only when not searching (general empty state)
            if (controller.searchQuery.isEmpty) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: controller.openFriendRequests,
                icon: const Icon(Icons.person_add),
                label: const Text('View Friend Requests'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
