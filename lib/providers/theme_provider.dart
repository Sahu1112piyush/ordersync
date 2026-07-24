import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_provider.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final localStorage = ref.watch(localStorageServiceProvider);
    return localStorage.isDarkMode() ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() async {
    final localStorage = ref.read(localStorageServiceProvider);
    final isDark = state == ThemeMode.dark;
    final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
    await localStorage.setDarkMode(!isDark);
    state = nextMode;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
