import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/friend_requests_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/widgets/friend_request_item.dart';

/// GetView that displays friend requests with tabbed interface
/// Features separate tabs for received and sent friend requests,
/// with real-time updates and interactive accept/decline functionality
class FriendRequestsView extends GetView<FriendRequestsController> {
  const FriendRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with back navigation
      appBar: AppBar(
        title: const Text('Friend Requests'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          // Custom tab bar for switching between received and sent requests
          _buildTabBar(),
          // Content area that shows different lists based on selected tab
          Expanded(
            child: Obx(() {
              // IndexedStack maintains state of both tabs while only showing one
              return IndexedStack(
                index: controller.selectedTabIndex,
                children: [
                  _buildReceivedRequestsList(), // Tab 0: Incoming friend requests
                  _buildSentRequestsList(),     // Tab 1: Outgoing friend requests
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Builds the custom tab bar with request counts and active state styling
  /// Shows number of received and sent requests with visual feedback
  /// @return Widget - The custom tab bar interface
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Obx(
            () => Row(
          children: [
            // Received requests tab
            Expanded(
              child: GestureDetector(
                onTap: () => controller.changeTab(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    // Highlight active tab with primary color
                    color: controller.selectedTabIndex == 0
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        // White icon on active tab, gray on inactive
                        color: controller.selectedTabIndex == 0
                            ? Colors.white
                            : AppTheme.textSecondaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      // Tab label with dynamic count from controller
                      Text(
                        'Received (${controller.receivedRequests.length})',
                        style: TextStyle(
                          color: controller.selectedTabIndex == 0
                              ? Colors.white
                              : AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Sent requests tab
            Expanded(
              child: GestureDetector(
                onTap: () => controller.changeTab(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    // Highlight active tab with primary color
                    color: controller.selectedTabIndex == 1
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send,
                        // White icon on active tab, gray on inactive
                        color: controller.selectedTabIndex == 1
                            ? Colors.white
                            : AppTheme.textSecondaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      // Tab label with dynamic count from controller
                      Text(
                        'Sent (${controller.sentRequests.length})',
                        style: TextStyle(
                          color: controller.selectedTabIndex == 1
                              ? Colors.white
                              : AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the list of received friend requests with accept/decline actions
  /// Shows empty state when no requests exist, otherwise displays interactive list
  /// @return Widget - The received requests list or empty state
  Widget _buildReceivedRequestsList() {
    return Obx(() {
      // Show empty state message when no received requests exist
      if (controller.receivedRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No friend requests',
          message:
          'When someone sends you a friend request, it will appear here',
        );
      }

      // Build scrollable list of received friend requests
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.receivedRequests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final request = controller.receivedRequests[index];
          // Get sender user data from controller's user cache
          final sender = controller.getUser(request.senderId);

          // Skip rendering if sender data is not available
          if (sender == null) return const SizedBox.shrink();

          return FriendRequestItem(
            request: request,
            user: sender,
            timeText: controller.getRequestTimeText(request.createdAt),
            isReceived: true, // Flag to show accept/decline buttons
            // Action callbacks for user interaction
            onAccept: () => controller.acceptFriendRequest(request),
            onDecline: () => controller.declineFriendRequest(request),
          );
        },
      );
    });
  }

  /// Builds the list of sent friend requests with status indicators
  /// Shows empty state when no requests exist, otherwise displays status-only list
  /// @return Widget - The sent requests list or empty state
  Widget _buildSentRequestsList() {
    return Obx(() {
      // Show empty state message when no sent requests exist
      if (controller.sentRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.send_outlined,
          title: 'No sent requests',
          message: 'Friend requests you send will appear here',
        );
      }

      // Build scrollable list of sent friend requests
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.sentRequests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final request = controller.sentRequests[index];
          // Get receiver user data from controller's user cache
          final receiver = controller.getUser(request.receiverId);

          // Skip rendering if receiver data is not available
          if (receiver == null) return const SizedBox.shrink();

          return FriendRequestItem(
            request: request,
            user: receiver,
            timeText: controller.getRequestTimeText(request.createdAt),
            isReceived: false, // Flag to show status instead of action buttons
            // Status information for sent requests
            statusText: controller.getStatusText(request.status),
            statusColor: controller.getStatusColor(request.status),
          );
        },
      );
    });
  }

  /// Builds a generic empty state display for when lists have no items
  /// Used by both received and sent request lists with different messaging
  /// @param icon - The icon to display in the empty state
  /// @param title - The main heading text
  /// @param message - The descriptive message text
  /// @return Widget - The empty state display
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with circular background
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            // Main heading text
            Text(
              title,
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            // Descriptive message text
            Text(
              message,
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
