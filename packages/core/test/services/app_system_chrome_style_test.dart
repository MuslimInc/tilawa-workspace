import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';

void main() {
  group('AppSystemChromeStyle.buildDefaultAppStyle', () {
    test('status bar icons follow scaffold, nav bar icons follow nav fill', () {
      const Color scaffold = Color(0xFFF5F5F5);
      const Color navBar = Color(0xFFFFFFFF);
      final theme = ThemeData(
        colorScheme: const ColorScheme.light(surface: navBar),
        scaffoldBackgroundColor: scaffold,
      );

      final SystemUiOverlayStyle style =
          AppSystemChromeStyle.buildDefaultAppStyle(
            theme,
            statusBarBackgroundColor: scaffold,
            navigationBarColor: navBar,
          );

      expect(style.statusBarIconBrightness, Brightness.dark);
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
      expect(style.statusBarColor, scaffold);
    });

    test('preserves fully transparent status bar color', () {
      final theme = ThemeData(
        colorScheme: const ColorScheme.light(),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      );

      final SystemUiOverlayStyle style =
          AppSystemChromeStyle.buildDefaultAppStyle(
            theme,
            statusBarBackgroundColor: const Color(0x00000000),
            navigationBarColor: const Color(0xFFFFFFFF),
          );

      expect(style.statusBarColor, const Color(0x00000000));
      expect(style.statusBarIconBrightness, Brightness.light);
    });
  });

  group('AppSystemChromeStyle.buildColoredScreenStyle', () {
    test('uses light icons on dark green launch background', () {
      const Color launchGreen = Color(0xFF219653);
      final SystemUiOverlayStyle style =
          AppSystemChromeStyle.buildColoredScreenStyle(
            backgroundColor: launchGreen,
          );

      expect(style.statusBarIconBrightness, Brightness.light);
      expect(style.statusBarColor, launchGreen);
      expect(style.systemNavigationBarColor, launchGreen);
    });
  });
}
