import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/routes/app_routes.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

/// StatefulWidget that provides the user registration interface
/// Features form validation, password confirmation, profile picture upload,
/// and integration with authentication controller for account creation
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Form key for validation handling
  final _formKey = GlobalKey<FormState>();

  // Text controllers for all input fields
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // AuthController instance for handling registration logic
  final AuthController _authController = Get.find<AuthController>();

  // Image picker for profile picture selection
  final ImagePicker _imagePicker = ImagePicker();

  // Local state variables for UI control
  bool _obscurePassword = true;           // Password field visibility toggle
  bool _obscureConfirmPassword = true;    // Confirm password field visibility toggle
  File? _selectedImage;                   // Selected profile picture file
  bool _isPickingImage = false;           // Image picker loading state

  @override
  void dispose() {
    // Clean up all controllers to prevent memory leaks
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                const SizedBox(height: 20),

                // Header section with back button and title
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Descriptive subtitle aligned with the title
                Padding(
                  padding: const EdgeInsets.only(left: 56), // Align with title text
                  child: Text(
                    'Fill in your details to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Display name input field with validation
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: Icon(Icons.person_outlined),
                    hintText: 'Enter your display name',
                  ),
                  validator: (value) {
                    // Check if display name is empty
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your display name';
                    }
                    // Validate minimum length for display name
                    if (value!.length < 2) {
                      return 'Display name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email input field with format validation
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
                const SizedBox(height: 16),

                // Confirm password field with matching validation
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    // Eye icon button to toggle confirm password visibility
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined  // Password hidden
                            : Icons.visibility_outlined,     // Password visible
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    hintText: 'Confirm your password',
                  ),
                  validator: (value) {
                    // Check if confirm password field is empty
                    if (value?.isEmpty ?? true) {
                      return 'Please confirm your password';
                    }
                    // Validate that passwords match
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Create account button with loading state
                // Uses Obx for reactive updates when auth controller loading state changes
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // Disable button during loading to prevent multiple submissions
                    onPressed: _authController.isLoading ? null : _signUp,
                    child: _authController.isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Create Account'),
                  ),
                )),
                const SizedBox(height: 24),

                // Profile picture upload section (optional)
                _buildProfilePictureSection(),
                const SizedBox(height: 32),

                // Sign in navigation link for existing users
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        'Sign In',
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

  /// Builds the optional profile picture upload section
  /// Contains image preview, upload/change buttons, and remove functionality
  /// @return Widget - The complete profile picture section
  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        // Container with light background and border for the profile section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Section title
              Text(
                'Profile Picture (Optional)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // Show either selected image preview or placeholder
              _selectedImage != null
                  ? _buildSelectedImagePreview()
                  : _buildImagePlaceholder(),
              const SizedBox(height: 16),

              // Show loading indicator or action button
              _isPickingImage
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                onPressed: _pickImage,
                // Change icon and text based on whether image is selected
                icon: Icon(_selectedImage != null ? Icons.edit : Icons.camera_alt),
                label: Text(_selectedImage != null ? 'Change Photo' : 'Add Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),

              // Show remove button only when image is selected
              if (_selectedImage != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the preview widget for the selected profile image
  /// Shows the image in a circular container with border styling
  /// @return Widget - The image preview widget
  Widget _buildSelectedImagePreview() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppTheme.primaryColor, width: 3),
      ),
      child: ClipOval(
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Builds the placeholder widget shown when no image is selected
  /// Displays a generic person icon in a circular gray container
  /// @return Widget - The placeholder widget
  Widget _buildImagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Icon(
        Icons.person,
        size: 50,
        color: Colors.grey[500],
      ),
    );
  }

  /// Handles the image selection process
  /// Shows a dialog to choose between camera and gallery, then picks the image
  /// Optimizes the selected image by resizing and compressing it
  Future<void> _pickImage() async {
    setState(() {
      _isPickingImage = true;
    });

    try {
      // Show dialog to choose image source (camera or gallery)
      final result = await Get.dialog<ImageSource>(
        AlertDialog(
          title: const Text('Select Photo'),
          content: const Text('Choose how you want to select your profile picture'),
          actions: [
            TextButton.icon(
              onPressed: () => Get.back(result: ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            TextButton.icon(
              onPressed: () => Get.back(result: ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
          ],
        ),
      );

      // If user selected a source, proceed with image picking
      if (result != null) {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: result,
          maxWidth: 512,        // Resize to maximum 512px width
          maxHeight: 512,       // Resize to maximum 512px height
          imageQuality: 80,     // Compress to 80% quality
        );

        // If image was successfully picked, update the state
        if (pickedFile != null) {
          setState(() {
            _selectedImage = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      // Show error message if image picking fails
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    } finally {
      // Always reset the loading state
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  /// Removes the currently selected profile image
  /// Resets the _selectedImage to null
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  /// Handles the registration process by validating the form and calling the auth controller
  /// Passes all form data including optional profile picture to the registration method
  void _signUp() {
    // Validate all form fields before attempting registration
    if (_formKey.currentState?.validate() ?? false) {
      // Call auth controller to handle registration with all user data
      _authController.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
        profilePicture: _selectedImage, // Optional profile picture
      );
    }
  }
}
