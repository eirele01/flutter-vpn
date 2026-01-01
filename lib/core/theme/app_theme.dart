import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF8B8B), // Pastel Red
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF5F5), // Very light red/pink
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF8B8B),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF2D1B1B), // Dark brownish red
      onSurface: const Color(0xFFFFE0E0),
    ),
    scaffoldBackgroundColor: const Color(0xFF1A1212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: const Color(0xFF3D2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
