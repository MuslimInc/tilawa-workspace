import 'package:flutter/material.dart';
import 'package:tilawa/core/env.dart';
import 'package:tilawa/features/theme/domain/app_theme_mode.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/features/theme/presentation/cubit/theme_cubit.dart';

/// Flutter bindings for [ThemeState] kept outside the cubit library so the cubit
/// stays free of Flutter imports (`bloc_lint` avoid_flutter_imports).
extension ThemeStateMaterial on ThemeState {
  /// The resolved primary color used to build [AppTheme].
  ///
  /// Production builds force the brand-locked Sage accent (see
  /// `docs/tilawa_brand.md` §3 and the `Env.kShowColorPicker` flag). Stored
  /// per-user state is preserved verbatim so dev/QA builds with
  /// `--dart-define=TILAWA_SHOW_COLOR_PICKER=true` can still preview the
  /// picker without a one-way migration.
  Color get primaryColor => Env.kShowColorPicker
      ? Color(primaryColorArgb)
      : Color(PrimaryColorPreset.brandLocked.valueArgb);

  ThemeMode get themeMode =>
      mode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
}
