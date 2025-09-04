import 'package:flutter/material.dart';

/// A centralized theme configuration class for the Flutter app.
/// This class defines all color constants and provides a complete light theme
/// with consistent styling across all UI components.
class AppTheme {

  // ==================== COLOR CONSTANTS ====================

  /// Primary brand color - A vibrant purple used for main actions and highlights
  static const Color primaryColor = Color(0xFF6C5CE7);

  /// Secondary brand color - A complementary blue for secondary actions
  static const Color secondaryColor = Color(0xFF74B9FF);

  // Status colors for different UI states
  /// Success state color - Green for positive feedback and success messages
  static const Color successColor = Color(0xFF00B894);

  /// Error state color - Orange-red for error messages and validation failures
  static const Color errorColor = Color(0xFFE17055);

  /// Warning state color - Yellow for warning messages and caution alerts
  static const Color warningColor = Color(0xFFFDCB6E);

  // Text colors for different content hierarchy
  /// Primary text color - Dark gray for main content and headings
  static const Color textPrimaryColor = Color(0xFF2D3436);

  /// Secondary text color - Medium gray for supporting text and labels
  static const Color textSecondaryColor = Color(0xFF636E72);

  // Background and surface colors
  /// Main background color - Light gray for app background
  static const Color backgroundColor = Color(0xFFF8F9FA);

  /// Card and surface color - Pure white for elevated elements
  static const Color cardColor = Color(0xFFFFFFFF);

  /// Border color - Light purple for borders and dividers
  static const Color borderColor = Color(0xFFDDD6FE);

  // ==================== LIGHT THEME CONFIGURATION ====================

  /// Returns a complete ThemeData configuration for the app's light theme.
  /// This theme follows Material 3 design principles and provides consistent
  /// styling for all Flutter UI components.
  static ThemeData get lightTheme {
    return ThemeData(
      // Enable Material 3 for modern UI components and styles.
      useMaterial3: true,

      // Generate a material color swatch from our primary color
      primarySwatch: _createMaterialColor(primaryColor),
      // Explicitly set the primary and scaffold background colors.
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,


      // AppBar Theme: Defines the style of the app's top bar.
      appBarTheme: const AppBarTheme(
        backgroundColor: cardColor, // Set a distinct background for the AppBar.
        foregroundColor: textPrimaryColor, // Color for icons and text on the AppBar.
        elevation: 0, // Flat design with no shadow.
        centerTitle: false, // Align the title to the left.
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme: Styling for cards and elevated containers.
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2, // A slight elevation for a subtle shadow effect.
        shadowColor: Colors.black.withOpacity(0.1), // A soft, subtle shadow.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners for a modern feel.
        ),
      ),

      // Input Decoration Theme: Styling for text fields (e.g., `TextField`).
      inputDecorationTheme: InputDecorationTheme(
        filled: true, // Enable a solid background for the input field.
        fillColor: cardColor, // Use the card color for the fill.
        // Define the border style for various states (default, enabled, focused, error).
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2), // Highlight with a thicker primary border on focus.
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor), // Use the error color for invalid input.
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        // Internal spacing within the input field
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        // Style for hint and label text within the input field.
        hintStyle: const TextStyle(color: textSecondaryColor),
        labelStyle: const TextStyle(color: textSecondaryColor),
      ),

      // Elevated Button Theme: Defines the style for solid-colored buttons.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Use the brand's primary color.
          foregroundColor: Colors.white, // White text for contrast.
          elevation: 0, // Flat design.
          // Internal spacing within the button
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Typography styling for button text
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme: Defines the style for low-emphasis, text-only buttons.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor, // The text color is the primary color.
          // Internal spacing within the button
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          // Typography styling for button text
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme: Defines the style for buttons with a border.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor), // The border is the primary color.
          // Internal spacing within the button
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Typography styling for button text
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Bottom Navigation Bar Theme: Styling for the bottom navigation menu.
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor, // Highlight the selected item with the primary color.
        unselectedItemColor: textSecondaryColor, // Subdued color for unselected items.
        type: BottomNavigationBarType.fixed, // Prevent resizing of icons on selection.
        elevation: 8,
        // Define text styles for selected and unselected labels.
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Text Theme: A complete set of text styles for different headings and body text.
      // This is the foundation for a consistent typography system.
      textTheme: const TextTheme(
        // Large headline text - Used for main page titles and major headings
        headlineLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        // Medium headline text - Used for section headers and important titles
        headlineMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        // Small headline text - Used for subsection headers
        headlineSmall: TextStyle(
          color: textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        // Large title text - Used for card titles and prominent labels
        titleLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        // Medium title text - Used for list item titles and form labels
        titleMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        // Large body text - Used for main content and descriptions
        bodyLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        // Medium body text - Used for regular content and paragraphs
        bodyMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        // Small body text - Used for captions, helper text, and fine print
        bodySmall: TextStyle(
          color: textSecondaryColor, // Lighter color for fine print or secondary info.
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Icon Theme: Defines the default color and size for all icons.
      iconTheme: const IconThemeData(
        color: textPrimaryColor,
        size: 24,
      ),

      // Divider Theme: Styling for horizontal and vertical dividers.
      dividerTheme: DividerThemeData(
        color: borderColor.withOpacity(0.5), // A semi-transparent border color.
        thickness: 1, // A thin line.
        space: 1,
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Creates a MaterialColor swatch from a single color.
  /// This generates different shades (50, 100, 200, etc.) of the given color
  /// which Flutter uses for various UI states and hover effects.
  ///
  /// [color] The base color to generate shades from
  /// Returns a MaterialColor with calculated color shades
  static MaterialColor _createMaterialColor(Color color) {
    // This is a standard algorithm to generate different shades of a color.
    // It is a common practice when defining a custom theme.
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    // Generate strength values from 0.1 to 0.9 (representing different shade intensities)
    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    // Calculate color variations for each strength level
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      // Create a new color shade by adjusting RGB values
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
