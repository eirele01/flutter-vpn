import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF6B6B), // Premium Pastel Red
      brightness: Brightness.light,
    ).copyWith(primary: const Color(0xFFFF6B6B), surface: Colors.white),
    scaffoldBackgroundColor: const Color(0xFFFBFBFB),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFF2D2D2D),
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(10),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF6B6B),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFFF6B6B),
      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white70,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212), // Charcoal
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
