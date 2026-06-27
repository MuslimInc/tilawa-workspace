import 'package:flutter/material.dart';

/// Semantic color roles for the Quran Sessions module, derived from the
/// active app [ColorScheme] so the feature matches MeMuslim theme colors.
abstract final class QuranSessionsPalette {
  /// Maps app [ColorScheme] tokens to tutoring-module roles.
  static ({
    Color primary,
    Color onPrimary,
    Color link,
    Color canvas,
    Color card,
    Color chipIdle,
    Color accentSoft,
    Color border,
    Color textPrimary,
    Color textSecondary,
    Color statusBackground,
    Color statusForeground,
    Color rating,
    Color destructive,
    Color destructiveSoft,
    Color onDestructive,
    Color disabledBackground,
    Color disabledForeground,
    Color disabledBorder,
    Color success,
    Color warning,
    Color info,
  })
  fromScheme(ColorScheme scheme) {
    return (
      primary: scheme.primary,
      onPrimary: scheme.onPrimary,
      link: scheme.primary,
      canvas: scheme.surfaceContainerLowest,
      card: scheme.surface,
      chipIdle: scheme.surfaceContainerHigh,
      accentSoft: scheme.primaryContainer,
      border: scheme.outlineVariant,
      textPrimary: scheme.onSurface,
      textSecondary: scheme.onSurfaceVariant,
      statusBackground: scheme.primaryContainer,
      statusForeground: scheme.onPrimaryContainer,
      rating: scheme.primary,
      destructive: scheme.error,
      destructiveSoft: scheme.errorContainer,
      onDestructive: scheme.onError,
      disabledBackground: scheme.onSurface.withValues(alpha: 0.12),
      disabledForeground: scheme.onSurface.withValues(alpha: 0.38),
      disabledBorder: scheme.outlineVariant.withValues(alpha: 0.64),
      success: scheme.tertiary,
      warning: scheme.error,
      info: scheme.primary,
    );
  }
}
