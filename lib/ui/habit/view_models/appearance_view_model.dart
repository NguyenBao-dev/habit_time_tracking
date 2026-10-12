import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide light/dark choice. Lives above the signed-in screens so the
/// theme also applies on the login screen. Until the user picks something,
/// the device setting is followed.
class AppearanceViewModel extends ChangeNotifier {
  static const _key = 'settings.darkMode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Whether the UI is dark right now, including when following the system.
  bool isDark(BuildContext context) =>
      _themeMode == ThemeMode.dark ||
          (_themeMode == ThemeMode.system &&
              MediaQuery.platformBrightnessOf(context) == Brightness.dark);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_key);
    _themeMode = saved == null
        ? ThemeMode.system
        : (saved ? ThemeMode.dark : ThemeMode.light);
    notifyListeners();
  }

  Future<void> setDarkMode(bool dark) async {
    final next = dark ? ThemeMode.dark : ThemeMode.light;
    if (next == _themeMode) return;
    _themeMode = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, dark);
  }
}