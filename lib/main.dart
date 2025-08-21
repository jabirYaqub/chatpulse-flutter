import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/firebase_options.dart';
import 'package:chat_app_flutter/routes/app_pages.dart';

// The main entry point of the application.
// This is where app initialization and setup happens.
void main() async {
  // Ensure that Flutter's widget binding is initialized before
  // running any asynchronous code. This is required for Firebase.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the default options for the current platform.
  // This must be done before using any Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Run the main application widget.
  runApp(const MyApp());
}

// MyApp is the root widget of the application.
// It's a StatelessWidget because its state does not change over time.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GetMaterialApp is a custom MaterialApp provided by the GetX package.
    // It's required to use GetX's routing, state management, and snackbars.
    return GetMaterialApp(
      // The title of the application, used by the OS.
      title: 'Flutter Chat App',

      // Define the light theme for the app using the custom AppTheme class.
      theme: AppTheme.lightTheme,

      // Set the theme mode to light.
      themeMode: ThemeMode.light,

      // The initial route for the app. This is the first screen shown.
      initialRoute: AppPages.initial,

      // Define the application's named routes using AppPages.
      // This allows for easy navigation between screens.
      getPages: AppPages.routes,

      // A flag to hide the debug banner in the top-right corner.
      debugShowCheckedModeBanner: false,
    );
  }
}