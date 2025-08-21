import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/friends_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/widgets/friend_list_item.dart';

class FriendsView extends GetView<FriendsController> {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if we came from New Chat button (navigation from home)
    final bool showBackButton = Get.arguments?['showBackButton'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        leading: showBackButton
            ? IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        )
            : const SizedBox(),
        actions: [
          IconButton(
            onPressed: controller.openFriendRequests,
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Friend Requests',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshFriends,
              child: Obx(() {
                if (controller.isLoading && controller.friends.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.filteredFriends.isEmpty) {
                  return _buildEmptyState();
                }

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
                      onTap: () => controller.startChat(friend),
                      onRemove: () => controller.removeFriend(friend),
                      onBlock: () => controller.blockFriend(friend),
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
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search friends...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() {
            return controller.searchQuery.isNotEmpty
                ? IconButton(
              onPressed: controller.clearSearch,
              icon: const Icon(Icons.clear),
            )
                : const SizedBox.shrink();
          }),
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

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(Get.context!).size.height * 0.6,
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'No friends found'
                  : 'No friends yet',
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Add friends to start chatting with them',
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
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