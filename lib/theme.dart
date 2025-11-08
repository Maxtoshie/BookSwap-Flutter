// lib/theme.dart
import 'package:flutter/material.dart';

/// Central theme configuration for BookSwap
class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFFFF9800); // AppBar, FAB, selected nav
  static const Color primaryDark = Color(0xFFE68900);

  // Backgrounds
  static const Color lightScaffold = Color(0xFFF5F5F5);
  static const Color darkScaffold = Color(0xFF121212);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Colors.white;

  // Chat Bubbles
  static const Color myMessage = primary;
  static const Color otherMessage = Color(0xFFE0E0E0);

  // Buttons
  static final ElevatedButtonThemeData elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFD700), // Gold
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );

  // FAB Theme
  static final FloatingActionButtonThemeData fabTheme =
      const FloatingActionButtonThemeData(
    backgroundColor: primary,
    foregroundColor: textOnPrimary,
  );

  // Card Theme (FIXED: Use CardThemeData)
  static final CardThemeData cardTheme = CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  // Bottom Navigation Bar
  static final BottomNavigationBarThemeData bottomNavTheme =
      BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: primary,
    unselectedItemColor: Colors.grey,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
  );

  // AppBar Theme
  static final AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: primary,
    foregroundColor: textOnPrimary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: const TextStyle(
      color: textOnPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  );

  // Text Theme
  static final TextTheme textTheme = TextTheme(
    displayLarge:
        const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
    titleLarge: const TextStyle(
        color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: const TextStyle(color: textPrimary),
    bodyMedium: TextStyle(color: textSecondary),
    labelLarge:
        const TextStyle(color: textOnPrimary, fontWeight: FontWeight.bold),
  );

  // Light Theme
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: lightScaffold,
    appBarTheme: appBarTheme,
    bottomNavigationBarTheme: bottomNavTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    floatingActionButtonTheme: fabTheme,
    cardTheme: cardTheme,
    textTheme: textTheme,
    iconTheme: const IconThemeData(color: textPrimary),
    dividerColor: Colors.grey[300],
  );

  // Dark Theme (optional but ready)
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: darkScaffold,
    appBarTheme: appBarTheme.copyWith(
      backgroundColor: primary,
    ),
    bottomNavigationBarTheme: bottomNavTheme.copyWith(
      backgroundColor: darkScaffold,
      selectedItemColor: primary,
      unselectedItemColor: Colors.grey[600],
    ),
    elevatedButtonTheme: elevatedButtonTheme,
    floatingActionButtonTheme: fabTheme,
    cardTheme: cardTheme.copyWith(
      color: Colors.grey[800],
    ),
    textTheme: textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerColor: Colors.grey[700],
  );
}
