/// A static class that holds all the named routes for the application.
/// Using a class like this helps to prevent typos and makes navigation more robust.
class AppRoutes {
  // =============================================================================
  // INITIAL SCREEN ROUTES
  // =============================================================================

  /// The route for the splash screen.
  /// This is typically the first screen users see when launching the app.
  static const String splash = '/';

  // =============================================================================
  // AUTHENTICATION ROUTES
  // =============================================================================

  /// Authentication routes.
  /// Route for the login screen where users enter their credentials.
  static const String login = '/login';

  /// Route for the registration screen where new users create accounts.
  static const String register = '/register';

  /// Route for the forgot password screen where users can reset their password.
  static const String forgotPassword = '/forgot-password';

  /// Route for the change password screen where authenticated users can update their password.
  static const String changePassword = '/change-password';

  // =============================================================================
  // MAIN APPLICATION SHELL
  // =============================================================================

  /// The route for the main navigation shell of the application.
  /// This typically contains the bottom navigation or drawer navigation structure.
  static const String main = '/main';

  // =============================================================================
  // CORE FEATURE ROUTES
  // =============================================================================

  /// Main application routes.
  /// Route for the home/dashboard screen - the primary landing page after authentication.
  static const String home = '/home';

  /// Route for the chat/messaging screen where users can communicate.
  static const String chat = '/chat';

  /// Route for the user profile screen where users can view and edit their information.
  static const String profile = '/profile';

  // =============================================================================
  // SOCIAL FEATURE ROUTES
  // =============================================================================

  /// Route for the users list screen showing all available users in the system.
  static const String usersList = '/users-list';

  /// Route for the friends screen displaying the user's current friends.
  static const String friends = '/friends';

  /// Route for the friend requests screen where users can manage incoming/outgoing requests.
  static const String friendRequests = '/friend-requests';

  /// Route for the notifications screen showing system and social notifications.
  static const String notifications = '/notifications';
}
