import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFFB71C1C), // Merah khas Toyota
  scaffoldBackgroundColor: const Color(0xFF121212), // Background utama gelap
  cardColor: const Color(0xFF1E1E1E),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(color: Colors.white),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.all(Colors.redAccent),
    trackColor: WidgetStateProperty.all(Colors.white24),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.redAccent,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  colorScheme: const ColorScheme.dark(
    primary: Colors.redAccent,
    secondary: Colors.white70,
    surface: Color(0xFF1E1E1E),
  ),
);
