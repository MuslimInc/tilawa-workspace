import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/theme/domain/app_theme_mode.dart';
import 'package:tilawa/features/theme/domain/entities/app_theme_preset.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';

/// Whether the current primary color came from a [PrimaryColorPreset] or a
/// user-picked custom HEX value.
enum PrimaryColorSource { preset, custom }

/// ARGB for [PrimaryColorPreset.teal] / [PrimaryColorPreset.defaultPreset].
const int _kDefaultPrimaryColorArgb = 0xFF1AADC5;

class ThemeState extends Equatable {
  const ThemeState({
    required this.mode,
    this.primaryColorArgb = _kDefaultPrimaryColorArgb,
    this.primaryColorSource = PrimaryColorSource.preset,
    this.primaryPresetId = 'teal',
    this.useSystemTheme = false,
    this.preset = AppThemePreset.defaultMode,
  });

  final AppThemeMode mode;

  /// Packed ARGB primary seed color for [AppTheme] generation.
  final int primaryColorArgb;
  final PrimaryColorSource primaryColorSource;

  /// Set when [primaryColorSource] is [PrimaryColorSource.preset]. Null for
  /// custom colors.
  final String? primaryPresetId;

  /// Persisted for backward compatibility, but currently deferred.
  ///
  /// This flag is restored and saved, however app runtime theming still uses
  /// [mode] directly (no OS-driven system theme wiring yet).
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
    AppThemeMode? mode,
    int? primaryColorArgb,
    PrimaryColorSource? primaryColorSource,
    String? primaryPresetId,
    bool clearPrimaryPresetId = false,
    bool? useSystemTheme,
    AppThemePreset? preset,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      primaryColorArgb: primaryColorArgb ?? this.primaryColorArgb,
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
    primaryColorArgb,
    primaryColorSource,
    primaryPresetId,
    useSystemTheme,
    preset,
  ];
}

@injectable
class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(mode: AppThemeMode.light));

  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    try {
      final modeValue = json['mode'] as String?;
      final AppThemeMode mode = switch (modeValue) {
        'dark' => AppThemeMode.dark,
        _ => AppThemeMode.light,
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

      int primaryColorArgb;
      PrimaryColorSource primaryColorSource;
      String? primaryPresetId;

      if (sourceValue == 'preset') {
        // New shape, preset source. Preset is canonical — its color wins
        // even if a stale `primaryColor` int was stored alongside.
        final preset =
            PrimaryColorPreset.findById(storedPresetId) ??
            PrimaryColorPreset.defaultPreset;
        primaryColorArgb = preset.valueArgb;
        primaryColorSource = PrimaryColorSource.preset;
        primaryPresetId = preset.id;
      } else if (sourceValue == 'custom' && colorValue != null) {
        // New shape, custom HEX preserved verbatim.
        primaryColorArgb = colorValue;
        primaryColorSource = PrimaryColorSource.custom;
        primaryPresetId = null;
      } else if (colorValue != null) {
        // Legacy payload (no source field). Migrate by ARGB lookup.
        final match = PrimaryColorPreset.findByArgb(colorValue);
        if (match != null) {
          primaryColorArgb = match.valueArgb;
          primaryColorSource = PrimaryColorSource.preset;
          primaryPresetId = match.id;
        } else {
          primaryColorArgb = colorValue;
          primaryColorSource = PrimaryColorSource.custom;
          primaryPresetId = null;
        }
      } else {
        // Missing/unparseable color → full default.
        primaryColorArgb = PrimaryColorPreset.defaultPreset.valueArgb;
        primaryColorSource = PrimaryColorSource.preset;
        primaryPresetId = PrimaryColorPreset.defaultPreset.id;
      }

      return ThemeState(
        mode: mode,
        primaryColorArgb: primaryColorArgb,
        primaryColorSource: primaryColorSource,
        primaryPresetId: primaryPresetId,
        useSystemTheme: useSystemTheme,
        preset: themePreset,
      );
    } catch (_) {
      return ThemeState(
        mode: AppThemeMode.light,
        primaryColorArgb: PrimaryColorPreset.defaultPreset.valueArgb,
        primaryColorSource: PrimaryColorSource.preset,
        primaryPresetId: PrimaryColorPreset.defaultPreset.id,
      );
    }
  }

  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    return {
      'mode': state.mode == AppThemeMode.dark ? 'dark' : 'light',
      'primaryColor': state.primaryColorArgb,
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

  Future<void> setMode(AppThemeMode mode) async {
    emit(state.copyWith(mode: mode));
  }

  /// Apply a predefined primary color from [PrimaryColorPreset].
  Future<void> setPrimaryPreset(PrimaryColorPreset preset) async {
    emit(
      state.copyWith(
        primaryColorArgb: preset.valueArgb,
        primaryColorSource: PrimaryColorSource.preset,
        primaryPresetId: preset.id,
      ),
    );
  }

  /// Apply a user-picked custom color as packed ARGB (same encoding as
  /// [Color.toARGB32]).
  Future<void> setPrimaryColorArgb(int argb) async {
    emit(
      state.copyWith(
        primaryColorArgb: argb,
        primaryColorSource: PrimaryColorSource.custom,
        clearPrimaryPresetId: true,
      ),
    );
  }

  Future<void> setUseSystemTheme(bool useSystemTheme) async {
    // Deferred field: persisted for compatibility, but not yet wired to
    // MaterialApp.themeMode / OS system wiring.
    emit(state.copyWith(useSystemTheme: useSystemTheme));
  }

  Future<void> toggleDark(bool enabled) async {
    await setMode(enabled ? AppThemeMode.dark : AppThemeMode.light);
  }
}
