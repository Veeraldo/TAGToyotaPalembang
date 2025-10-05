import 'package:flutter/material.dart';
import 'dark_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme =>
      _isDarkMode ? darkTheme : ThemeData.light();

  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;
    notifyListeners(); // <- ini WAJIB biar MaterialApp rebuild
  }
}
