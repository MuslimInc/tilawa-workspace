import 'package:equatable/equatable.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/features/theme/data/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends Equatable {
  final ThemeMode mode;
  final FlexScheme scheme;
  final bool useSystemTheme;

  const ThemeState({
    required this.mode,
    this.scheme = FlexScheme.mandyRed,
    this.useSystemTheme = true,
  });

  @override
  List<Object?> get props => [mode, scheme, useSystemTheme];
}

@injectable
class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeKey = 'app_theme_mode';
  static const String _schemeKey = 'app_theme_scheme';
  static const String _useSystemThemeKey = 'app_use_system_theme';

  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(const ThemeState(mode: ThemeMode.system)) {
    _load();
  }

  void _load() {
    final themeValue = _prefs.getString(_themeKey);
    final schemeValue = _prefs.getString(_schemeKey);
    final useSystemTheme = _prefs.getBool(_useSystemThemeKey) ?? true;

    final mode = switch (themeValue) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final scheme = FlexScheme.values.firstWhere(
      (s) => s.name == schemeValue,
      orElse: () => FlexScheme.mandyRed,
    );

    emit(
      ThemeState(mode: mode, scheme: scheme, useSystemTheme: useSystemTheme),
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(
      ThemeState(
        mode: mode,
        scheme: state.scheme,
        useSystemTheme: state.useSystemTheme,
      ),
    );

    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_themeKey, value);
  }

  Future<void> setScheme(FlexScheme scheme) async {
    emit(
      ThemeState(
        mode: state.mode,
        scheme: scheme,
        useSystemTheme: state.useSystemTheme,
      ),
    );

    await _prefs.setString(_schemeKey, scheme.name);
  }

  Future<void> setUseSystemTheme(bool useSystemTheme) async {
    emit(
      ThemeState(
        mode: state.mode,
        scheme: state.scheme,
        useSystemTheme: useSystemTheme,
      ),
    );

    await _prefs.setBool(_useSystemThemeKey, useSystemTheme);
  }

  Future<void> toggleDark(bool enabled) async {
    await setMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  /// Get the current light theme
  ThemeData getLightTheme() {
    return FlexThemeData.light(
      scheme: state.scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      appBarStyle: FlexAppBarStyle.primary,
      appBarOpacity: 0.95,
      appBarElevation: 0,
      transparentStatusBar: true,
      tabBarStyle: FlexTabBarStyle.forAppBar,
      tooltipsMatchBackground: true,
      swapColors: false,
      lightIsWhite: false,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      useMaterial3ErrorColors: true,
    );
  }

  /// Get the current dark theme
  ThemeData getDarkTheme() {
    return FlexThemeData.dark(
      scheme: state.scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      appBarStyle: FlexAppBarStyle.background,
      appBarOpacity: 0.90,
      appBarElevation: 0,
      transparentStatusBar: true,
      tabBarStyle: FlexTabBarStyle.forAppBar,
      tooltipsMatchBackground: true,
      swapColors: false,
      darkIsTrueBlack: false,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      useMaterial3ErrorColors: true,
    );
  }

  /// Get available color schemes
  List<FlexScheme> getAvailableSchemes() {
    return ThemeService.getAvailableSchemes();
  }
}
