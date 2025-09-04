import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

/// StatefulWidget that provides the login interface for the chat application
/// Features email/password authentication with form validation, loading states,
/// password visibility toggle, and navigation to registration and password reset
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Form key for validation handling
  final _formKey = GlobalKey<FormState>();

  // Text controllers for input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // AuthController instance for handling authentication logic
  final AuthController _authController = Get.find<AuthController>();

  // Local state for password visibility toggle
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // App logo/icon with chat bubble design
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Welcome heading text
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),

                // Descriptive subtitle for user guidance
                Text(
                  'Sign in to continue chatting with your friends',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 40),

                // Email input field with validation
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'Enter your email',
                  ),
                  validator: (value) {
                    // Check if email field is empty
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    // Validate email format using GetX utility
                    if (!GetUtils.isEmail(value!)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password input field with visibility toggle and validation
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    // Eye icon button to toggle password visibility
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined  // Password hidden
                            : Icons.visibility_outlined,     // Password visible
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    hintText: 'Enter your password',
                  ),
                  validator: (value) {
                    // Check if password field is empty
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your password';
                    }
                    // Validate minimum password length
                    if (value!.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sign In button with loading state
                // Uses Obx for reactive updates when auth controller loading state changes
                Obx(
                      () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // Disable button during loading to prevent multiple submissions
                      onPressed: _authController.isLoading ? null : _signIn,
                      child: _authController.isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Sign In'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Forgot password navigation link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Get.toNamed(AppRoutes.forgotPassword);
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Divider with "OR" text for visual separation
                Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.borderColor)),
                  ],
                ),
                const SizedBox(height: 32),

                // Sign up navigation link for new users
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.register),
                      child: Text(
                        'Sign Up',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handles the sign-in process by validating the form and calling the auth controller
  /// Only proceeds with authentication if form validation passes
  void _signIn() {
    // Validate form fields before attempting sign in
    if (_formKey.currentState?.validate() ?? false) {
      // Call auth controller to handle sign in with trimmed email and password
      _authController.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }
}
