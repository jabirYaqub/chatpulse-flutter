import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/main_controller.dart';
import 'package:chat_app_flutter/views/home_view.dart';
import 'package:chat_app_flutter/views/friends_view.dart';
import 'package:chat_app_flutter/views/users_list_view.dart';
import 'package:chat_app_flutter/views/profile_view.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

/// GetView that provides the main app container with bottom navigation
/// Features a PageView for smooth transitions between main sections and
/// a bottom navigation bar with badge indicators for unread messages
/// Serves as the root container for all main app functionality
class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PageView allows smooth horizontal swiping between main sections
      body: PageView(
        controller: controller.pageController,
        // Update bottom nav when user swipes between pages
        onPageChanged: controller.onPageChanged,
        children: [
          const HomeView(),        // Tab 0: Main chat list and conversations
          const FriendsView(),     // Tab 1: Friends list management
          const UsersListView(),   // Tab 2: Discover and find new people
          const ProfileView(),     // Tab 3: User profile and settings
        ],
      ),
      // Bottom navigation with reactive badge indicators
      bottomNavigationBar: Obx(
            () => BottomNavigationBar(
          currentIndex: controller.currentIndex,
          onTap: controller.changeTabIndex,
          type: BottomNavigationBarType.fixed, // All tabs always visible
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondaryColor,
          backgroundColor: Colors.white,
          elevation: 8,
          items: [
            // Chats tab with unread message badge
            BottomNavigationBarItem(
              icon: _buildIconWithBadge(
                Icons.chat_outlined,
                controller.getUnreadCount(), // Show unread message count
              ),
              activeIcon: _buildIconWithBadge(
                Icons.chat,
                controller.getUnreadCount(),
              ),
              label: 'Chats',
            ),
            // Friends tab - no badge needed
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined),
              activeIcon: Icon(Icons.people),
              label: 'Friends',
            ),
            // Find Friends tab - no badge needed
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_search_outlined),
              activeIcon: Icon(Icons.person_search),
              label: 'Find Friends',
            ),
            // Profile tab - no badge needed
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an icon with an optional red badge for unread counts
  /// Used primarily for the chats tab to show unread message notifications
  /// @param icon - The IconData to display
  /// @param count - The number to show in the badge (0 = no badge)
  /// @return Widget - Icon with optional positioned badge overlay
  Widget _buildIconWithBadge(IconData icon, int count) {
    return Stack(
      children: [
        // Main navigation icon
        Icon(icon),
        // Red notification badge (only shown when count > 0)
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.errorColor, // Red background for urgency
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
              child: Text(
                // Show "99+" for counts over 99 to prevent badge overflow
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
