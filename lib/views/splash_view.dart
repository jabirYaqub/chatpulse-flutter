/// Splash view is created after defining theme in app_theme.dart
/// After creating routes in app_pages.dart and app_routes.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';

/// StatefulWidget that provides the app's splash screen with animated branding
/// Features fade and scale animations while checking user authentication status
/// Automatically navigates to login or main screen based on auth state
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  // Animation controller for managing the splash screen animations
  late AnimationController _animationController;

  // Fade animation for smooth appearance of splash elements
  late Animation<double> _fadeAnimation;

  // Scale animation for elastic entrance effect of app icon
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with 2-second duration
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Create fade animation with ease-in curve for smooth appearance
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Create scale animation with elastic bounce effect for engaging entrance
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Start the animations
    _animationController.forward();

    // Begin authentication check and navigation process
    _checkAuthAndNavigate();
  }

  /// Handles authentication verification and automatic navigation
  /// Waits for animations to complete before checking auth state
  /// Navigates to main screen if authenticated, login screen otherwise
  void _checkAuthAndNavigate() async {
    // Wait for animation to complete (matches animation duration)
    await Future.delayed(const Duration(seconds: 2));

    // Initialize AuthController as permanent instance for app-wide access
    final authController = Get.put(AuthController(), permanent: true);

    // Brief additional delay to ensure auth state is fully determined
    await Future.delayed(const Duration(milliseconds: 500));

    // Navigate based on authentication status
    if (authController.isAuthenticated) {
      // User is signed in - go to main app interface
      Get.offAllNamed(AppRoutes.main);
    } else {
      // User not signed in - go to login screen
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    // Clean up animation controller to prevent memory leaks
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor, // Brand color background
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon container with shadow styling
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App name/brand title
                    Text(
                      'ChatPulse',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // App tagline/description
                    Text(
                      'Connect with friends instantly',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 64),

                    // Loading indicator to show app is initializing
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
