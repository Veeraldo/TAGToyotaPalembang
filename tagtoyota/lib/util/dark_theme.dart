import 'package:flutter/material.dart';

const Color primaryColor = Color.fromARGB(255, 0, 0, 0); // Hitam
const Color secondaryColor = Color.fromARGB(255, 255, 0, 0); // Merah
const Color accentColor = Color(0xFFFBF9FA); // Putih

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: primaryColor,
  colorScheme: ColorScheme.dark(
    primary: secondaryColor,
    secondary: accentColor,
    surface: primaryColor,
    background: primaryColor,
    onPrimary: accentColor,
    onSecondary: accentColor,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: accentColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: secondaryColor,
      foregroundColor: accentColor,
    ),
  ),
  useMaterial3: true,
);
