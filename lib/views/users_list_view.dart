import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/users_list_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/widgets/user_list_item.dart';

/// GetView that displays a searchable list of users for discovery and friend requests
/// Features real-time search filtering and relationship management actions
/// Allows users to find new people to connect with in the chat application
class UsersListView extends GetView<UsersListController> {
  const UsersListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar without back button since this is accessed from main navigation
      appBar: AppBar(title: const Text('Find Peoples'), leading: SizedBox()),
      body: Column(
        children: [
          // Search bar for filtering users by name or other criteria
          _buildSearchBar(),
          // Main content area with user list or empty state
          Expanded(
            child: Obx(() {
              // Show empty state when no users match current search/filter
              if (controller.filteredUsers.isEmpty) {
                return _buildEmptyState();
              }

              // Build scrollable list of users with relationship actions
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredUsers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = controller.filteredUsers[index];
                  return UserListItem(
                    user: user,
                    // Handle different relationship actions (add friend, message, etc.)
                    onTap: () => controller.handleRelationshipAction(user),
                    controller: controller,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Builds the search bar for filtering users in real-time
  /// Features dynamic clear button and responsive styling states
  /// @return Widget - The search input interface
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
        // Update search results as user types
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(Icons.search),
          // Dynamic clear button - only shown when there's search text
          suffixIcon: Obx(() {
            return controller.searchQuery.isNotEmpty
                ? IconButton(
              onPressed: controller.clearSearch,
              icon: const Icon(Icons.clear),
            )
                : const SizedBox.shrink(); // Hide when search is empty
          }),
          // Custom border styling for different interaction states
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
  /// Shows different content based on whether user is searching or no users exist
  /// @return Widget - The empty state interface
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
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
                  ? 'No users found'        // When searching but no results
                  : 'No users available',   // When no users exist at all
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            // Dynamic message text based on search state
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'Try a different search term'         // Search guidance
                  : 'Users will appear here when they join', // General empty state
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
