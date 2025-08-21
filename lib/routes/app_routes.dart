/// A static class that holds all the named routes for the application.
/// Using a class like this helps to prevent typos and makes navigation more robust.
class AppRoutes {
  /// The route for the splash screen.
  static const String splash = '/';

  /// Authentication routes.
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';

  /// The route for the main navigation shell of the application.
  static const String main = '/main';

  /// Main application routes.
  static const String home = '/home';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String usersList = '/users-list';
  static const String friends = '/friends';
  static const String friendRequests = '/friend-requests';
  static const String notifications = '/notifications';
}