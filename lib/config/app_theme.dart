import 'package:flutter/material.dart';

class AppTheme {
  // Domino's Brand Colors
  static const Color dominosBlue = Color(0xFF0B6BB8); // Domino's Blue
  static const Color dominosRed = Color(0xFFE31837);  // Domino's Red
  static const Color dominosLightBlue = Color(0xFF0579CD);
  static const Color dominosDarkBlue = Color(0xFF005DAA);
  static const Color dominosYellow = Color(0xFFFED200); // Yellow accent
  
  // Semantic colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFE31837); // Use Domino's red for errors
  
  // Light Theme - Domino's Style
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: dominosBlue,
        brightness: Brightness.light,
        primary: dominosBlue,
        secondary: dominosRed,
        error: errorColor,
        tertiary: dominosYellow,
      ),
      
      // Typography - Bold and modern like Domino's
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        displaySmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
      ),
      
      // App Bar Theme - Domino's Blue
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
        backgroundColor: dominosBlue,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Card Theme - Bold shadows and rounded corners
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
      ),
      
      // Floating Action Button - Domino's Red
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 6,
        backgroundColor: dominosRed,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dominosBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      
      // Elevated Button - Domino's Red with bold style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Pill shape
          ),
          elevation: 4,
          backgroundColor: dominosRed,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: dominosBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      
      // Outlined Button - Blue outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: const BorderSide(color: dominosBlue, width: 2),
          foregroundColor: dominosBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        elevation: 16,
        backgroundColor: Colors.white,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dominosRed;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dominosRed.withValues(alpha: 0.5);
          }
          return Colors.grey.shade300;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dominosBlue;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
    );
  }
  
  // Dark Theme - Domino's Style
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: dominosBlue,
        brightness: Brightness.dark,
        primary: dominosLightBlue,
        secondary: dominosRed,
        error: errorColor,
        tertiary: dominosYellow,
        surface: const Color(0xFF1A1A1A),
      ),
      
      // Typography - Same bold style
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.white),
        displayMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.white),
        displaySmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
      ),
      
      // App Bar Theme - Dark with Domino's Blue accent
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Card Theme - Dark cards with elevation
      cardTheme: CardThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF262626),
      ),
      
      // Floating Action Button - Domino's Red
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 8,
        backgroundColor: dominosRed,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dominosLightBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
      ),
      
      // Elevated Button - Domino's Red with bold style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Pill shape
          ),
          elevation: 6,
          backgroundColor: dominosRed,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: dominosLightBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      
      // Outlined Button - Blue outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: const BorderSide(color: dominosLightBlue, width: 2),
          foregroundColor: dominosLightBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        elevation: 16,
        backgroundColor: Color(0xFF1A1A1A),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dominosRed;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dominosRed.withValues(alpha: 0.5);
          }
          return Colors.grey.shade700;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dominosLightBlue;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
    );
  }
}
