import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFFFBF9FA); // Putih
const Color secondaryColor = Color.fromARGB(255, 255, 0, 0); // Merah
const Color accentColor = Color(0xFF2B2024); // Hitam

final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: secondaryColor,
    brightness: Brightness.light,
    primary: primaryColor,
    secondary: secondaryColor,
    tertiary: accentColor,
    surface: primaryColor,
    background: primaryColor,
    onPrimary: accentColor,
    onSecondary: primaryColor, 
    onTertiary: primaryColor,
    onSurface: accentColor, 
    onBackground: accentColor,
    error: const Color.fromARGB(255, 255, 0, 0),
    onError: primaryColor,
  ),
  scaffoldBackgroundColor: primaryColor,
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: accentColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: secondaryColor,
      foregroundColor: primaryColor,
    ),
  ),
  useMaterial3: true,
);
