import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/theme/domain/entities/app_theme_preset.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Whether the current primary color came from a [PrimaryColorPreset] or a
/// user-picked custom HEX value.
enum PrimaryColorSource { preset, custom }

class ThemeState extends Equatable {
  const ThemeState({
    required this.mode,
    this.primaryColor = AppColors.primaryTeal,
    this.primaryColorSource = PrimaryColorSource.preset,
    this.primaryPresetId = 'teal',
    this.useSystemTheme = false,
    this.preset = AppThemePreset.defaultMode,
  });

  final ThemeMode mode;
  final Color primaryColor;
  final PrimaryColorSource primaryColorSource;

  /// Set when [primaryColorSource] is [PrimaryColorSource.preset]. Null for
  /// custom colors.
  final String? primaryPresetId;

  /// Persisted for backward compatibility, but currently deferred.
  ///
  /// This flag is restored and saved, however app runtime theming still uses
  /// [mode] directly (no [ThemeMode.system] wiring yet).
  final bool useSystemTheme;

  /// Persisted theme-preset bucket for deferred/partial theme variants.
  ///
  /// - [AppThemePreset.trueBlack] has a partial runtime effect in dark theme
  ///   generation.
  /// - [AppThemePreset.highContrast] is currently reserved and has no runtime
  ///   effect.
  ///
  /// These values are intentionally persisted for backward-compatible state
  /// evolution.
  final AppThemePreset preset;

  ThemeState copyWith({
    ThemeMode? mode,
    Color? primaryColor,
    PrimaryColorSource? primaryColorSource,
    String? primaryPresetId,
    bool clearPrimaryPresetId = false,
    bool? useSystemTheme,
    AppThemePreset? preset,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      primaryColor: primaryColor ?? this.primaryColor,
      primaryColorSource: primaryColorSource ?? this.primaryColorSource,
      primaryPresetId: clearPrimaryPresetId
          ? null
          : (primaryPresetId ?? this.primaryPresetId),
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      preset: preset ?? this.preset,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    primaryColor,
    primaryColorSource,
    primaryPresetId,
    useSystemTheme,
    preset,
  ];
}

@injectable
class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(mode: ThemeMode.light));

  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    try {
      final modeValue = json['mode'] as String?;
      final ThemeMode mode = switch (modeValue) {
        'dark' => ThemeMode.dark,
        _ => ThemeMode.light,
      };

      final bool useSystemTheme = json['useSystemTheme'] as bool? ?? false;

      final presetName = json['preset'] as String?;
      final themePreset = AppThemePreset.values.firstWhere(
        (e) => e.name == presetName,
        orElse: () => AppThemePreset.defaultMode,
      );

      final colorValue = json['primaryColor'] as int?;
      final sourceValue = json['primaryColorSource'] as String?;
      final storedPresetId = json['primaryPresetId'] as String?;

      Color primaryColor;
      PrimaryColorSource primaryColorSource;
      String? primaryPresetId;

      if (sourceValue == 'preset') {
        // New shape, preset source. Preset is canonical — its color wins
        // even if a stale `primaryColor` int was stored alongside.
        final preset =
            PrimaryColorPreset.findById(storedPresetId) ??
            PrimaryColorPreset.defaultPreset;
        primaryColor = preset.value;
        primaryColorSource = PrimaryColorSource.preset;
        primaryPresetId = preset.id;
      } else if (sourceValue == 'custom' && colorValue != null) {
        // New shape, custom HEX preserved verbatim.
        primaryColor = Color(colorValue);
        primaryColorSource = PrimaryColorSource.custom;
        primaryPresetId = null;
      } else if (colorValue != null) {
        // Legacy payload (no source field). Migrate by ARGB lookup.
        final match = PrimaryColorPreset.findByArgb(colorValue);
        if (match != null) {
          primaryColor = match.value;
          primaryColorSource = PrimaryColorSource.preset;
          primaryPresetId = match.id;
        } else {
          primaryColor = Color(colorValue);
          primaryColorSource = PrimaryColorSource.custom;
          primaryPresetId = null;
        }
      } else {
        // Missing/unparseable color → full default.
        primaryColor = PrimaryColorPreset.defaultPreset.value;
        primaryColorSource = PrimaryColorSource.preset;
        primaryPresetId = PrimaryColorPreset.defaultPreset.id;
      }

      return ThemeState(
        mode: mode,
        primaryColor: primaryColor,
        primaryColorSource: primaryColorSource,
        primaryPresetId: primaryPresetId,
        useSystemTheme: useSystemTheme,
        preset: themePreset,
      );
    } catch (_) {
      return ThemeState(
        mode: ThemeMode.light,
        primaryColor: PrimaryColorPreset.defaultPreset.value,
        primaryColorSource: PrimaryColorSource.preset,
        primaryPresetId: PrimaryColorPreset.defaultPreset.id,
      );
    }
  }

  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    return {
      'mode': state.mode == ThemeMode.dark ? 'dark' : 'light',
      'primaryColor': state.primaryColor.toARGB32(),
      'primaryColorSource':
          state.primaryColorSource == PrimaryColorSource.custom
          ? 'custom'
          : 'preset',
      'primaryPresetId': state.primaryPresetId,
      'useSystemTheme': state.useSystemTheme,
      'preset': state.preset.name,
    };
  }

  Future<void> setPreset(AppThemePreset preset) async {
    emit(state.copyWith(preset: preset));
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(state.copyWith(mode: mode));
  }

  /// Apply a predefined primary color from [PrimaryColorPreset].
  Future<void> setPrimaryPreset(PrimaryColorPreset preset) async {
    emit(
      state.copyWith(
        primaryColor: preset.value,
        primaryColorSource: PrimaryColorSource.preset,
        primaryPresetId: preset.id,
      ),
    );
  }

  /// Apply a user-picked custom HEX color. Marks the source as
  /// [PrimaryColorSource.custom] and clears the preset id.
  Future<void> setPrimaryColor(Color color) async {
    emit(
      state.copyWith(
        primaryColor: color,
        primaryColorSource: PrimaryColorSource.custom,
        clearPrimaryPresetId: true,
      ),
    );
  }

  Future<void> setUseSystemTheme(bool useSystemTheme) async {
    // Deferred field: persisted for compatibility, but not yet wired to
    // MaterialApp.themeMode / ThemeMode.system behavior.
    emit(state.copyWith(useSystemTheme: useSystemTheme));
  }

  Future<void> toggleDark(bool enabled) async {
    await setMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  /// Whether the cubit's current primary color is the brand default preset.
  /// Used to opt into the hand-tuned default **dark** primary on surface in
  /// [AppTheme]. Light `primaryContainer` always follows `_containerForPrimary`.
  bool get _isDefaultPreset =>
      state.primaryColorSource == PrimaryColorSource.preset &&
      state.primaryPresetId == PrimaryColorPreset.defaultPreset.id;

  /// Get the current light theme
  ThemeData getLightTheme() {
    return AppTheme.getLightTheme(primaryColor: state.primaryColor);
  }

  /// Get the current dark theme
  ThemeData getDarkTheme() {
    return AppTheme.getDarkTheme(
      primaryColor: state.primaryColor,
      isDefaultPreset: _isDefaultPreset,
      // Partial wiring only: trueBlack currently affects dark theme surfaces.
      // highContrast remains reserved/deferred at runtime.
      darkIsTrueBlack: state.preset == AppThemePreset.trueBlack,
    );
  }
}
