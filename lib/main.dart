import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/firebase_options.dart';
import 'package:chat_app_flutter/routes/app_pages.dart';

/// The main entry point of the Flutter Chat Application.
/// This function performs essential initialization tasks before starting the app:
/// - Initializes Flutter's widget binding system
/// - Sets up Firebase for backend services
/// - Launches the main application widget
void main() async {
  // Ensure that Flutter's widget binding is initialized before
  // running any asynchronous code. This is required for Firebase.
  // Must be called before any async operations in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific configuration.
  // This connects the app to Firebase services like Authentication,
  // Firestore, Storage, etc. Must complete before app startup.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Launch the main application widget after all initialization is complete.
  // This starts the Flutter app lifecycle and renders the first screen.
  runApp(const MyApp());
}

/// MyApp is the root widget of the entire Flutter application.
/// It configures the app-wide settings including:
/// - Theme configuration (colors, fonts, styles)
/// - Navigation system and routing
/// - Initial screen and route management
/// - Development/debug settings
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GetMaterialApp is GetX's enhanced version of MaterialApp.
    // Benefits over standard MaterialApp:
    // - Built-in dependency injection
    // - Advanced routing with named routes
    // - State management integration
    // - Simplified snackbars and dialogs
    return GetMaterialApp(
      // Application title displayed in the OS task switcher
      // and used for accessibility purposes
      title: 'Flutter Chat App',

      // App-wide light theme configuration using custom AppTheme
      // Defines colors, typography, button styles, etc.
      theme: AppTheme.lightTheme,

      // Force light theme mode (could be light, dark, or system)
      // System would follow device theme preference
      themeMode: ThemeMode.light,

      // The first route/screen shown when the app launches
      // Defined in AppPages.initial constant
      initialRoute: AppPages.initial,

      // Complete routing configuration for the application
      // Maps route names to page widgets and handles navigation
      getPages: AppPages.routes,

      // Hide the "DEBUG" banner in development builds
      // Should be false for production, true during development for debugging
      debugShowCheckedModeBanner: false,
    );
  }
}
