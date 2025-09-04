// Import GetX package for state management and routing
import 'package:get/get.dart';
// Import main controller that manages the app's primary navigation
import 'package:chat_app_flutter/controllers/main_controller.dart';
// Import route constants for navigation
import 'package:chat_app_flutter/routes/app_routes.dart';
// Authentication view imports
import 'package:chat_app_flutter/views/auth/forgot_password_view.dart';
import 'package:chat_app_flutter/views/auth/change_password_view.dart';
// Core app views
import 'package:chat_app_flutter/views/main_view.dart';
import 'package:chat_app_flutter/views/splash_view.dart';
import 'package:chat_app_flutter/views/auth/login_view.dart';
import 'package:chat_app_flutter/views/auth/register_view.dart';
// Feature-specific views
import 'package:chat_app_flutter/views/home_view.dart';
import 'package:chat_app_flutter/views/chat_view.dart';
import 'package:chat_app_flutter/views/profile_view.dart';
import 'package:chat_app_flutter/views/users_list_view.dart';
import 'package:chat_app_flutter/views/friends_view.dart';
import 'package:chat_app_flutter/views/friend_requests_view.dart';
import 'package:chat_app_flutter/views/notifications_view.dart';
// Feature-specific controllers
import 'package:chat_app_flutter/controllers/home_controller.dart';
import 'package:chat_app_flutter/controllers/chat_controller.dart';
import 'package:chat_app_flutter/controllers/profile_controller.dart';
import 'package:chat_app_flutter/controllers/users_list_controller.dart';
import 'package:chat_app_flutter/controllers/friends_controller.dart';
import 'package:chat_app_flutter/controllers/friend_requests_controller.dart';
import 'package:chat_app_flutter/controllers/notifications_controller.dart';

/// A class that defines all the application's pages and their routes.
///
/// This centralized routing configuration manages navigation throughout the app,
/// including route definitions, page associations, and dependency injection bindings.
/// It follows the GetX routing pattern for clean navigation management.
///
/// The class organizes routes into logical groups:
/// - Authentication routes (login, register, password management)
/// - Main navigation route (bottom navigation container)
/// - Feature routes (home, chat, profile, etc.)
class AppPages {
  /// The initial route of the application.
  ///
  /// This is the first page shown when the app launches.
  /// The splash screen typically handles initialization tasks like:
  /// - Checking authentication status
  /// - Loading initial configuration
  /// - Deciding whether to navigate to login or main view
  static const initial = AppRoutes.splash;

  /// A list of all the application's routes and their associated pages and bindings.
  ///
  /// Each GetPage entry defines:
  /// - name: The route path used for navigation
  /// - page: The widget to display for this route
  /// - binding: Optional dependency injection for controllers
  ///
  /// Routes are organized in logical groups for better maintainability.
  /// Controllers are lazy-loaded using BindingsBuilder to optimize memory usage.
  static final routes = [
    /// Splash Screen Route
    ///
    /// Entry point of the application that handles:
    /// - App initialization
    /// - Authentication check
    /// - Initial navigation decision
    /// No binding needed as splash logic is typically self-contained
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),

    /// Authentication Routes
    ///
    /// These routes handle user authentication flows.
    /// No bindings are defined here as auth controllers might be
    /// initialized globally or use different state management approach.

    // Login page for existing users
    GetPage(name: AppRoutes.login, page: () => const LoginView()),

    // Registration page for new users
    GetPage(name: AppRoutes.register, page: () => const RegisterView()),

    // Password recovery flow for users who forgot their credentials
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
    ),

    // Password change functionality for authenticated users
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
    ),

    /// Main Navigation Route with its controller
    ///
    /// This is the primary container view that hosts the bottom navigation
    /// and manages switching between main app sections (home, chat, profile, etc.).
    /// The MainController coordinates navigation state and bottom bar interactions.
    GetPage(
      name: AppRoutes.main,
      page: () => const MainView(),
      // Use a BindingsBuilder to initialize the MainController.
      // This ensures the controller is created when navigating to this route
      // and disposed when leaving (if using Get.delete())
      binding: BindingsBuilder(() {
        Get.put(MainController());
      }),
    ),

    /// Main App Routes with their respective controllers
    ///
    /// These are the primary feature pages of the application.
    /// Each route has its own controller that manages the page's state and logic.
    /// Controllers are initialized lazily when the route is accessed.

    // Home/Dashboard view - typically shows recent chats, quick actions
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      // Initialize HomeController when navigating to the HomeView.
      // Controller handles fetching recent chats, user status, etc.
      binding: BindingsBuilder(() {
        Get.put(HomeController());
      }),
    ),

    // Individual chat conversation view
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatView(),
      // Initialize ChatController when navigating to the ChatView.
      // Controller manages message sending/receiving, typing indicators, etc.
      // Note: May receive parameters like chatId or userId via Get.arguments
      binding: BindingsBuilder(() {
        Get.put(ChatController());
      }),
    ),

    // User profile management view
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      // Initialize ProfileController when navigating to the ProfileView.
      // Controller handles profile updates, photo uploads, status changes
      binding: BindingsBuilder(() {
        Get.put(ProfileController());
      }),
    ),

    // Browse and search all users in the app
    GetPage(
      name: AppRoutes.usersList,
      page: () => const UsersListView(),
      // Initialize UsersListController when navigating to the UsersListView.
      // Controller manages user search, filtering, and pagination
      binding: BindingsBuilder(() {
        Get.put(UsersListController());
      }),
    ),

    // View and manage friend connections
    GetPage(
      name: AppRoutes.friends,
      page: () => const FriendsView(),
      // Initialize FriendsController when navigating to the FriendsView.
      // Controller handles friend list display, online status, unfriend actions
      binding: BindingsBuilder(() {
        Get.put(FriendsController());
      }),
    ),

    // Manage incoming and outgoing friend requests
    GetPage(
      name: AppRoutes.friendRequests,
      page: () => const FriendRequestsView(),
      // Initialize FriendRequestsController when navigating to the FriendRequestsView.
      // Controller manages accept/decline actions, request notifications
      binding: BindingsBuilder(() {
        Get.put(FriendRequestsController());
      }),
    ),

    // Notification center for all app notifications
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      // Initialize NotificationsController when navigating to the NotificationsView.
      // Controller handles notification display, mark as read, clear actions
      binding: BindingsBuilder(() {
        Get.put(NotificationsController());
      }),
    ),
  ];
}
