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
    final ColorScheme lightScheme = ColorScheme.fromSeed(
      seedColor: dominosBlue,
      brightness: Brightness.light,
      primary: dominosBlue,
      onPrimary: Colors.white,
      secondary: dominosRed,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF1A1C1E),
      surfaceContainerHighest: const Color(0xFFE1E2E8),
      onSurfaceVariant: const Color(0xFF44474E),
      outline: const Color(0xFF74777F),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightScheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FF),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
      
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1A1C1E),
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1C1E),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: dominosBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: dominosBlue,
          foregroundColor: Colors.white,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dominosBlue,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dominosBlue,
          side: const BorderSide(color: dominosBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
  
  // Dark Theme - Domino's Style
  static ThemeData get darkTheme {
    final ColorScheme darkScheme = ColorScheme.fromSeed(
      seedColor: dominosBlue,
      brightness: Brightness.dark,
      primary: dominosLightBlue,
      onPrimary: Colors.white,
      secondary: dominosRed,
      onSecondary: Colors.white,
      surface: const Color(0xFF111318),
      onSurface: const Color(0xFFE2E2E6),
      surfaceContainerHighest: const Color(0xFF262626),
      onSurfaceVariant: const Color(0xFFC4C6D0),
      outline: const Color(0xFF8E9099),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: const Color(0xFF0E1014),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
      
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE2E2E6),
        titleTextStyle: TextStyle(
          color: Color(0xFFE2E2E6),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1A1C22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF2D3036)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: dominosLightBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2D3036)),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1C22),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: dominosLightBlue,
          foregroundColor: Colors.white,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dominosLightBlue,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dominosLightBlue,
          side: const BorderSide(color: dominosLightBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
