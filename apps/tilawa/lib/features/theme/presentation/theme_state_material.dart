import 'package:flutter/material.dart';
import 'package:tilawa/features/theme/domain/app_theme_mode.dart';
import 'package:tilawa/features/theme/presentation/cubit/theme_cubit.dart';

/// Flutter bindings for [ThemeState] kept outside the cubit library so the cubit
/// stays free of Flutter imports (`bloc_lint` avoid_flutter_imports).
extension ThemeStateMaterial on ThemeState {
  Color get primaryColor => Color(primaryColorArgb);

  ThemeMode get themeMode =>
      mode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
}
