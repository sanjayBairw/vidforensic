import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemePrefKey = 'app_theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  late final Future<void> initialized;

  ThemeModeNotifier() : super(ThemeMode.light) {
    initialized = _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kThemePrefKey);
      if (saved == 'dark') {
        state = ThemeMode.dark;
      } else if (saved == 'system') {
        state = ThemeMode.system;
      } else {
        // Light mode is the default for first-time users
        state = ThemeMode.light;
      }
    } catch (_) {
      // Default to light mode on error
      state = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'light';
      if (mode == ThemeMode.dark) {
        val = 'dark';
      } else if (mode == ThemeMode.system) {
        val = 'system';
      }
      await prefs.setString(_kThemePrefKey, val);
    } catch (_) {}
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
