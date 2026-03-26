import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/theme/domain/entities/app_theme_preset.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class ThemeState extends Equatable {
  const ThemeState({
    required this.mode,
    this.primaryColor = AppColors.defaultPrimary,
    this.useSystemTheme = true,
    this.preset = AppThemePreset.defaultMode,
  });
  final ThemeMode mode;
  final Color primaryColor;
  final bool useSystemTheme;
  final AppThemePreset preset;

  @override
  List<Object?> get props => [mode, primaryColor, useSystemTheme, preset];
}

class AppColorOption {
  const AppColorOption({required this.name, required this.color});
  final String name;
  final Color color;
}

@injectable
class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(mode: ThemeMode.system));

  static const List<AppColorOption> colorOptions = [
    AppColorOption(name: 'Cyan', color: AppColors.primaryCyan),
    AppColorOption(name: 'Green', color: AppColors.primaryGreen),
    AppColorOption(name: 'Brown', color: AppColors.primaryBrown),
    AppColorOption(name: 'Purple', color: AppColors.primaryPurple),
  ];

  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    try {
      final modeValue = json['mode'] as String?;
      final colorValue = json['primaryColor'] as int?;
      final bool useSystemTheme = json['useSystemTheme'] as bool? ?? true;

      final ThemeMode mode = switch (modeValue) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

      final Color primaryColor = colorValue != null
          ? Color(colorValue)
          : AppColors.defaultPrimary;

      final presetName = json['preset'] as String?;
      final preset = AppThemePreset.values.firstWhere(
        (e) => e.name == presetName,
        orElse: () => AppThemePreset.defaultMode,
      );

      return ThemeState(
        mode: mode,
        primaryColor: primaryColor,
        useSystemTheme: useSystemTheme,
        preset: preset,
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
      'primaryColor': state.primaryColor.toARGB32(),
      'useSystemTheme': state.useSystemTheme,
      'preset': state.preset.name,
    };
  }

  Future<void> setPreset(AppThemePreset preset) async {
    emit(
      ThemeState(
        mode: state.mode,
        primaryColor: state.primaryColor,
        useSystemTheme: state.useSystemTheme,
        preset: preset,
      ),
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(
      ThemeState(
        mode: mode,
        primaryColor: state.primaryColor,
        useSystemTheme: state.useSystemTheme,
        preset: state.preset,
      ),
    );
  }

  Future<void> setPrimaryColor(Color color) async {
    emit(
      ThemeState(
        mode: state.mode,
        primaryColor: color,
        useSystemTheme: state.useSystemTheme,
        preset: state.preset,
      ),
    );
  }

  Future<void> setUseSystemTheme(bool useSystemTheme) async {
    emit(
      ThemeState(
        mode: state.mode,
        primaryColor: state.primaryColor,
        useSystemTheme: useSystemTheme,
        preset: state.preset,
      ),
    );
  }

  Future<void> toggleDark(bool enabled) async {
    await setMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  /// Get the current light theme
  ThemeData getLightTheme() {
    return AppTheme.getLightTheme(primaryColor: state.primaryColor);
  }

  /// Get the current dark theme
  ThemeData getDarkTheme() {
    return AppTheme.getDarkTheme(
      primaryColor: state.primaryColor,
      darkIsTrueBlack: state.preset == AppThemePreset.trueBlack,
    );
  }
}
