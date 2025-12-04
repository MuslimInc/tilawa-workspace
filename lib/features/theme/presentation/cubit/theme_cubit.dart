import 'package:equatable/equatable.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/theme_service.dart';

class ThemeState extends Equatable {
  const ThemeState({
    required this.mode,
    this.scheme = FlexScheme.green,
    this.useSystemTheme = true,
  });
  final ThemeMode mode;
  final FlexScheme scheme;
  final bool useSystemTheme;

  @override
  List<Object?> get props => [mode, scheme, useSystemTheme];
}

@injectable
class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(mode: ThemeMode.system));

  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    try {
      final modeValue = json['mode'] as String?;
      final schemeValue = json['scheme'] as String?;
      final bool useSystemTheme = json['useSystemTheme'] as bool? ?? true;

      final ThemeMode mode = switch (modeValue) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

      final FlexScheme scheme = FlexScheme.values.firstWhere(
        (s) => s.name == schemeValue,
        orElse: () => FlexScheme.green,
      );

      return ThemeState(
        mode: mode,
        scheme: scheme,
        useSystemTheme: useSystemTheme,
      );
    } catch (e) {
      return const ThemeState(mode: ThemeMode.system);
    }
  }

  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    return {
      'mode': switch (state.mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
      'scheme': state.scheme.name,
      'useSystemTheme': state.useSystemTheme,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(
      ThemeState(
        mode: mode,
        scheme: state.scheme,
        useSystemTheme: state.useSystemTheme,
      ),
    );
  }

  Future<void> setScheme(FlexScheme scheme) async {
    emit(
      ThemeState(
        mode: state.mode,
        scheme: scheme,
        useSystemTheme: state.useSystemTheme,
      ),
    );
  }

  Future<void> setUseSystemTheme(bool useSystemTheme) async {
    emit(
      ThemeState(
        mode: state.mode,
        scheme: state.scheme,
        useSystemTheme: useSystemTheme,
      ),
    );
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
      tabBarStyle: FlexTabBarStyle.forAppBar,
      tooltipsMatchBackground: true,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
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
      tabBarStyle: FlexTabBarStyle.forAppBar,
      tooltipsMatchBackground: true,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3ErrorColors: true,
    );
  }

  /// Get available color schemes
  List<FlexScheme> getAvailableSchemes() {
    return ThemeService.getAvailableSchemes();
  }
}
