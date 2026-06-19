import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = LocalStorageService.instance.getBool(
      LocalStorageService.themeKey,
    );
    if (isDark == true) {
      state = ThemeMode.dark;
    }
  }

  Future<void> toggle() async {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await LocalStorageService.instance.setBool(
      LocalStorageService.themeKey,
      state == ThemeMode.dark,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await LocalStorageService.instance.setBool(
      LocalStorageService.themeKey,
      mode == ThemeMode.dark,
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
