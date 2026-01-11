import 'package:flutter/material.dart';

class AppTheme {
  // Domino's Brand Colors
  static const Color dominosBlue = Color(0xFF0B6BB8); // Domino's Blue
  static const Color dominosRed = Color(0xFFE31837); // Domino's Red
  static const Color dominosLightBlue = Color(0xFF0579CD);
  static const Color dominosDarkBlue = Color(0xFF005DAA);
  static const Color dominosYellow = Color(0xFFFED200); // Yellow accent

  // Semantic colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(
    0xFFE31837,
  ); // Use Domino's red for errors

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
      error: dominosRed,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightScheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FF),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        },
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -1),
        displayMedium: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
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
          letterSpacing: -0.5,
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
        elevation: 6,
        backgroundColor: dominosBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: dominosBlue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dominosBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dominosBlue,
          side: const BorderSide(color: dominosBlue, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Dark Theme - Neon Stealth Edition
  static ThemeData get darkTheme {
    const primaryColor = Color(0xFF4FC3F7); // Neon Blue
    const accentColor = Color(0xFFFF5252); // Turbo Red
    const surfaceColor = Color(0xFF161B22); // Carbon Dark
    const backgroundColor = Color(0xFF0D1117); // Stealth Deep

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        onPrimary: Colors.black,
        secondary: accentColor,
        onSecondary: Colors.white,
        surface: backgroundColor,
        onSurface: const Color(0xFFE2E2E6),
        surfaceContainerHighest: surfaceColor,
        onSurfaceVariant: const Color(0xFF8B949E),
        outline: const Color(0xFF30363D),
        error: accentColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        },
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE2E2E6),
        titleTextStyle: TextStyle(
          color: Color(0xFFE2E2E6),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Colors.white12, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 8,
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            fontSize: 16,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
