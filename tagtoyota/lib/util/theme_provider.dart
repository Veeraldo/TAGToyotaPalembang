import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  get themeMode => null;

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}
