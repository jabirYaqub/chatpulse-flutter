import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/main_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';
import 'package:chat_app_flutter/views/auth/forgot_password_view.dart';
import 'package:chat_app_flutter/views/auth/change_password_view.dart';
import 'package:chat_app_flutter/views/main_view.dart';
import 'package:chat_app_flutter/views/splash_view.dart';
import 'package:chat_app_flutter/views/auth/login_view.dart';
import 'package:chat_app_flutter/views/auth/register_view.dart';
import 'package:chat_app_flutter/views/home_view.dart';
import 'package:chat_app_flutter/views/chat_view.dart';
import 'package:chat_app_flutter/views/profile_view.dart';
import 'package:chat_app_flutter/views/users_list_view.dart';
import 'package:chat_app_flutter/views/friends_view.dart';
import 'package:chat_app_flutter/views/friend_requests_view.dart';
import 'package:chat_app_flutter/views/notifications_view.dart';
import 'package:chat_app_flutter/controllers/home_controller.dart';
import 'package:chat_app_flutter/controllers/chat_controller.dart';
import 'package:chat_app_flutter/controllers/profile_controller.dart';
import 'package:chat_app_flutter/controllers/users_list_controller.dart';
import 'package:chat_app_flutter/controllers/friends_controller.dart';
import 'package:chat_app_flutter/controllers/friend_requests_controller.dart';
import 'package:chat_app_flutter/controllers/notifications_controller.dart';

/// A class that defines all the application's pages and their routes.
class AppPages {
  /// The initial route of the application.
  static const initial = AppRoutes.splash;

  /// A list of all the application's routes and their associated pages and bindings.
  static final routes = [
    /// Splash Screen Route
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),

    /// Authentication Routes
    GetPage(name: AppRoutes.login, page: () => const LoginView()),
    GetPage(name: AppRoutes.register, page: () => const RegisterView()),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
    ),

    /// Main Navigation Route with its controller
    GetPage(
      name: AppRoutes.main,
      page: () => const MainView(),
      // Use a BindingsBuilder to initialize the MainController.
      binding: BindingsBuilder(() {
        Get.put(MainController());
      }),
    ),

    /// Main App Routes with their respective controllers
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      // Initialize HomeController when navigating to the HomeView.
      binding: BindingsBuilder(() {
        Get.put(HomeController());
      }),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatView(),
      // Initialize ChatController when navigating to the ChatView.
      binding: BindingsBuilder(() {
        Get.put(ChatController());
      }),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      // Initialize ProfileController when navigating to the ProfileView.
      binding: BindingsBuilder(() {
        Get.put(ProfileController());
      }),
    ),
    GetPage(
      name: AppRoutes.usersList,
      page: () => const UsersListView(),
      // Initialize UsersListController when navigating to the UsersListView.
      binding: BindingsBuilder(() {
        Get.put(UsersListController());
      }),
    ),
    GetPage(
      name: AppRoutes.friends,
      page: () => const FriendsView(),
      // Initialize FriendsController when navigating to the FriendsView.
      binding: BindingsBuilder(() {
        Get.put(FriendsController());
      }),
    ),
    GetPage(
      name: AppRoutes.friendRequests,
      page: () => const FriendRequestsView(),
      // Initialize FriendRequestsController when navigating to the FriendRequestsView.
      binding: BindingsBuilder(() {
        Get.put(FriendRequestsController());
      }),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      // Initialize NotificationsController when navigating to the NotificationsView.
      binding: BindingsBuilder(() {
        Get.put(NotificationsController());
      }),
    ),
  ];
}