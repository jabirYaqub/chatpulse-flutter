import 'package:flutter/material.dart';

// The AppTheme class is responsible for defining the application's visual theme.
// It uses a static class pattern to provide a single, consistent theme throughout the app.
class AppTheme {
  // --- Color Palette Definitions ---
  // A clean and well-organized color palette is crucial for a cohesive design.
  // These are the base colors used across the app, named for their purpose.

  // Primary colors for the application's brand identity.
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color secondaryColor = Color(0xFF74B9FF);

  // Status colors to provide visual feedback for success, error, and warning states.
  static const Color successColor = Color(0xFF00B894);
  static const Color errorColor = Color(0xFFE17055);
  static const Color warningColor = Color(0xFFFDCB6E);

  // Text colors for different levels of hierarchy.
  static const Color textPrimaryColor = Color(0xFF2D3436);
  static const Color textSecondaryColor = Color(0xFF636E72);

  // Background colors for the main screen and elevated surfaces (e.g., cards).
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  // A subtle border color, often used for input fields or separators.
  static const Color borderColor = Color(0xFFDDD6FE);

  // --- Light Theme Definition ---
  // This static getter provides a complete ThemeData object for the light theme.
  // Using a getter allows for potential future logic or more complex theme setup.
  static ThemeData get lightTheme {
    return ThemeData(
      // Enable Material 3 for modern UI components and styles.
      useMaterial3: true,
      // Create a swatch from the primary color to generate shades. This is necessary
      // for components that use `primarySwatch`, like `FloatingActionButton`.
      primarySwatch: _createMaterialColor(primaryColor),
      // Explicitly set the primary and scaffold background colors.
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,

      // --- Component-Specific Themes ---
      // These sections define the look and feel of specific widgets.
      // This approach ensures consistency across all instances of a widget type.

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        headlineLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
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

  // --- Utility Method ---
  // This is a private helper method used to generate a MaterialColor swatch.
  // MaterialColor is required by `primarySwatch` in `ThemeData`.
  static MaterialColor _createMaterialColor(Color color) {
    // This is a standard algorithm to generate different shades of a color.
    // It is a common practice when defining a custom theme.
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
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