import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/home_controller.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/controllers/main_controller.dart';
import 'package:chat_app_flutter/widgets/chat_list_item.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, authController),
      body: Column(
        children: [
          _buildSearchBar(),
          Obx(
                () => controller.isSearching && controller.searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _buildQuickFilters(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshChats,
              color: AppTheme.primaryColor,
              backgroundColor: Colors.white,
              child: Obx(() {
                if (controller.chats.isEmpty) {
                  if (controller.isSearching &&
                      controller.searchQuery.isNotEmpty) {
                    return _buildNoSearchResults();
                  } else if (controller.activeFilter != 'All') {
                    return _buildNoFilterResults();
                  } else {
                    return _buildEmptyState();
                  }
                }

                return _buildChatsList();
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

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
          // Profile picture that's clickable
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

  Widget _buildNotificationButton() {
    return Obx(() {
      final unreadNotifications = controller.getUnreadNotificationsCount();

      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
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
          onChanged: controller.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey[500],
              size: 20,
            ),
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

  Widget _buildQuickFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Obx(
                  () => _buildFilterChip(
                'All',
                    () => controller.setFilter('All'),
                controller.activeFilter == 'All',
              ),
            ),
            const SizedBox(width: 8),
            Obx(
                  () => _buildFilterChip(
                'Unread (${controller.getUnreadCount()})',
                    () => controller.setFilter('Unread'),
                controller.activeFilter == 'Unread',
              ),
            ),
            const SizedBox(width: 8),
            Obx(
                  () => _buildFilterChip(
                'Recent (${controller.getRecentCount()})',
                    () => controller.setFilter('Recent'),
                controller.activeFilter == 'Recent',
              ),
            ),
            const SizedBox(width: 8),
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

  Widget _buildFilterChip(String label, VoidCallback onTap, bool isSelected) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
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
          if (!controller.isSearching || controller.searchQuery.isEmpty)
            _buildChatsHeader(),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: controller.isSearching ? 16 : 8,
              ),
              itemCount: controller.chats.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey[200], indent: 72),
              itemBuilder: (context, index) {
                final chat = controller.chats[index];
                final otherUser = controller.getOtherUser(chat);

                if (otherUser == null) {
                  return const SizedBox.shrink();
                }

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

  Widget _buildChatsHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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

  Widget _buildEmptyState() {
    return SingleChildScrollView(
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
                _buildEmptyStateIcon(),
                const SizedBox(height: 24),
                _buildEmptyStateText(),
                const SizedBox(height: 32),
                _buildEmptyStateActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildEmptyStateActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final mainController = Get.find<MainController>();
              mainController.changeTabIndex(2);
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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final mainController = Get.find<MainController>();
              mainController.changeTabIndex(1);
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