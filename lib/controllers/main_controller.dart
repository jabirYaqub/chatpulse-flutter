import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:chat_app_flutter/controllers/friends_controller.dart';
import 'package:chat_app_flutter/controllers/home_controller.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/controllers/profile_controller.dart';
import 'package:chat_app_flutter/controllers/users_list_controller.dart';

class MainController extends GetxController {
  final RxInt _currentIndex = 0.obs;
  final PageController pageController = PageController();

  int get currentIndex => _currentIndex.value;

  @override
  void onInit() {
    super.onInit();
    // Initialize all required controllers
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => FriendsController());
    Get.lazyPut(() => UsersListController());
    Get.lazyPut(() => ProfileController());
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void changeTabIndex(int index) {
    _currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void onPageChanged(int index) {
    _currentIndex.value = index;
  }

  // Get unread count for badge on home tab
  int getUnreadCount() {
    try {
      final homeController = Get.find<HomeController>();
      return homeController.getTotalUnreadCount();
    } catch (e) {
      return 0;
    }
  }

  // Get notification count for badge on notifications tab
  int getNotificationCount() {
    try {
      final homeController = Get.find<HomeController>();
      return homeController.getUnreadNotificationsCount();
    } catch (e) {
      return 0;
    }
  }
}
