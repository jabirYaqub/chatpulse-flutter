import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/friend_requests_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/widgets/friend_request_item.dart';

class FriendRequestsView extends GetView<FriendRequestsController> {
  const FriendRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: Obx(() {
              return IndexedStack(
                index: controller.selectedTabIndex,
                children: [
                  _buildReceivedRequestsList(),
                  _buildSentRequestsList(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

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
            Expanded(
              child: GestureDetector(
                onTap: () => controller.changeTab(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
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
                        color: controller.selectedTabIndex == 0
                            ? Colors.white
                            : AppTheme.textSecondaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
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
            Expanded(
              child: GestureDetector(
                onTap: () => controller.changeTab(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
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
                        color: controller.selectedTabIndex == 1
                            ? Colors.white
                            : AppTheme.textSecondaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
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

  Widget _buildReceivedRequestsList() {
    return Obx(() {
      if (controller.receivedRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No friend requests',
          message:
          'When someone sends you a friend request, it will appear here',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.receivedRequests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final request = controller.receivedRequests[index];
          final sender = controller.getUser(request.senderId);

          if (sender == null) return const SizedBox.shrink();

          return FriendRequestItem(
            request: request,
            user: sender,
            timeText: controller.getRequestTimeText(request.createdAt),
            isReceived: true,
            onAccept: () => controller.acceptFriendRequest(request),
            onDecline: () => controller.declineFriendRequest(request),
          );
        },
      );
    });
  }

  Widget _buildSentRequestsList() {
    return Obx(() {
      if (controller.sentRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.send_outlined,
          title: 'No sent requests',
          message: 'Friend requests you send will appear here',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.sentRequests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final request = controller.sentRequests[index];
          final receiver = controller.getUser(request.receiverId);

          if (receiver == null) return const SizedBox.shrink();

          return FriendRequestItem(
            request: request,
            user: receiver,
            timeText: controller.getRequestTimeText(request.createdAt),
            isReceived: false,
            statusText: controller.getStatusText(request.status),
            statusColor: controller.getStatusColor(request.status),
          );
        },
      );
    });
  }

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
            Text(
              title,
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
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
