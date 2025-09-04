import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:chat_app_flutter/controllers/friends_controller.dart';
import 'package:chat_app_flutter/controllers/home_controller.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/controllers/profile_controller.dart';
import 'package:chat_app_flutter/controllers/users_list_controller.dart';

/// MainController manages the core navigation and tab system of the app.
/// This controller coordinates the bottom navigation bar, page transitions,
/// and lazy initialization of feature controllers for optimal performance.
///
/// This controller is responsible for:
/// - Managing bottom navigation tab state and transitions
/// - Controlling PageView navigation with smooth animations
/// - Lazy initialization of feature controllers to optimize app startup
/// - Providing badge counts for tabs (unread messages, notifications)
/// - Coordinating between different main app sections
/// - Memory management through proper controller disposal
/// - Synchronizing tab selection with page view state
class MainController extends GetxController {

  // ==================== NAVIGATION STATE ====================

  /// Current selected tab index (0-based: Home, Friends, Users, Profile)
  final RxInt _currentIndex = 0.obs;

  /// PageController for managing smooth transitions between main app screens
  /// This enables swiping between tabs and programmatic navigation with animations
  final PageController pageController = PageController();

  // ==================== PUBLIC GETTERS ====================

  /// Returns the currently selected tab index for UI state management
  int get currentIndex => _currentIndex.value;

  // ==================== LIFECYCLE METHODS ====================

  /// Controller initialization - sets up lazy loading of feature controllers
  @override
  void onInit() {
    super.onInit();
    // Initialize all required controllers using lazy loading for better performance.
    // Lazy loading means controllers are only created when first accessed,
    // reducing initial app startup time and memory usage.

    /// Home screen controller for chat list and main dashboard
    Get.lazyPut(() => HomeController());

    /// Friends management controller for friend list and operations
    Get.lazyPut(() => FriendsController());

    /// User discovery controller for finding and adding new users
    Get.lazyPut(() => UsersListController());

    /// Profile management controller for user settings and account
    Get.lazyPut(() => ProfileController());
  }

  /// Controller cleanup - disposes resources to prevent memory leaks
  @override
  void onClose() {
    // Dispose PageController to free up memory and prevent memory leaks
    pageController.dispose();
    super.onClose();
  }

  // ==================== NAVIGATION METHODS ====================

  /// Changes the active tab with animated page transition
  /// This method is called when user taps on bottom navigation items
  void changeTabIndex(int index) {
    // Update the reactive tab index state
    _currentIndex.value = index;

    // Animate to the selected page with smooth transition
    // Duration and curve provide polished user experience
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  /// Updates tab index when user swipes between pages
  /// This method is called by PageView's onPageChanged callback
  /// to keep tab selection synchronized with page swiping
  void onPageChanged(int index) {
    _currentIndex.value = index;
  }

  // ==================== BADGE COUNT METHODS ====================

  /// Get unread message count for badge display on home tab
  /// This provides visual indication of unread messages across all chats
  int getUnreadCount() {
    try {
      // Attempt to access HomeController and get total unread count
      final homeController = Get.find<HomeController>();
      return homeController.getTotalUnreadCount();
    } catch (e) {
      // Return 0 if HomeController is not yet initialized or any error occurs
      // This prevents UI crashes and provides graceful degradation
      return 0;
    }
  }

  /// Get unread notification count for badge display on notifications/profile tab
  /// This shows users when they have pending notifications to review
  int getNotificationCount() {
    try {
      // Access HomeController to get notification count
      // HomeController manages notification data along with chat data
      final homeController = Get.find<HomeController>();
      return homeController.getUnreadNotificationsCount();
    } catch (e) {
      // Return 0 if controller not available or error occurs
      // Ensures UI remains stable even if data isn't ready
      return 0;
    }
  }
}
