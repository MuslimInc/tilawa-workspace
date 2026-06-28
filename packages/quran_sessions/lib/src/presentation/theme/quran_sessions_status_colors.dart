import 'package:flutter/material.dart';

/// Semantic colors for Quran Sessions **session / booking / availability**
/// states.
///
/// This is the *only* visual concept the feature owns. Everything else —
/// spacing, radius, typography, neutral/brand colors, cards, chrome — comes
/// from the global MeMuslim UI Kit theme (`theme.tokens`, `theme.textTheme`,
/// `colorScheme`). Do not add layout, typography, or generic palette tokens
/// here.
@immutable
class QuranSessionsStatusColors
    extends ThemeExtension<QuranSessionsStatusColors> {
  const QuranSessionsStatusColors({
    required this.upcoming,
    required this.completed,
    required this.cancelled,
    required this.cancelledSoft,
    required this.rejected,
    required this.missed,
    required this.joinAvailable,
    required this.joinUnavailable,
    required this.scheduledBackground,
    required this.scheduledForeground,
    required this.rating,
  });

  /// Scheduled / confirmed / pending-approval upcoming session accent.
  final Color upcoming;

  /// Completed session accent.
  final Color completed;

  /// Cancelled session foreground accent.
  final Color cancelled;

  /// Soft background behind cancelled / rejected status chips.
  final Color cancelledSoft;

  /// Rejected-by-tutor foreground accent.
  final Color rejected;

  /// Missed / no-show session accent.
  final Color missed;

  /// Join affordance when the session can be joined.
  final Color joinAvailable;

  /// Join affordance when the session cannot be joined.
  final Color joinUnavailable;

  /// Scheduled badge background (price chip, summary strip).
  final Color scheduledBackground;

  /// Scheduled badge foreground.
  final Color scheduledForeground;

  /// Teacher rating star accent.
  final Color rating;

  static QuranSessionsStatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<QuranSessionsStatusColors>() ??
        fromScheme(theme.colorScheme);
  }

  /// Maps the active [ColorScheme] to session status roles.
  ///
  /// Values intentionally mirror the legacy feature palette so this extraction
  /// is behaviour-preserving. (`missed` currently shares [ColorScheme.error]
  /// with [cancelled]; giving it a distinct hue is a tracked follow-up.)
  static QuranSessionsStatusColors fromScheme(ColorScheme scheme) {
    return QuranSessionsStatusColors(
      upcoming: scheme.primary,
      completed: scheme.tertiary,
      cancelled: scheme.error,
      cancelledSoft: scheme.errorContainer,
      rejected: scheme.error,
      missed: scheme.error,
      joinAvailable: scheme.primary,
      joinUnavailable: scheme.onSurface.withValues(alpha: 0.38),
      scheduledBackground: scheme.primaryContainer,
      scheduledForeground: scheme.onPrimaryContainer,
      rating: scheme.primary,
    );
  }

  @override
  QuranSessionsStatusColors copyWith({
    Color? upcoming,
    Color? completed,
    Color? cancelled,
    Color? cancelledSoft,
    Color? rejected,
    Color? missed,
    Color? joinAvailable,
    Color? joinUnavailable,
    Color? scheduledBackground,
    Color? scheduledForeground,
    Color? rating,
  }) {
    return QuranSessionsStatusColors(
      upcoming: upcoming ?? this.upcoming,
      completed: completed ?? this.completed,
      cancelled: cancelled ?? this.cancelled,
      cancelledSoft: cancelledSoft ?? this.cancelledSoft,
      rejected: rejected ?? this.rejected,
      missed: missed ?? this.missed,
      joinAvailable: joinAvailable ?? this.joinAvailable,
      joinUnavailable: joinUnavailable ?? this.joinUnavailable,
      scheduledBackground: scheduledBackground ?? this.scheduledBackground,
      scheduledForeground: scheduledForeground ?? this.scheduledForeground,
      rating: rating ?? this.rating,
    );
  }

  @override
  QuranSessionsStatusColors lerp(
    covariant QuranSessionsStatusColors? other,
    double t,
  ) {
    if (other == null) return this;
    return QuranSessionsStatusColors(
      upcoming: Color.lerp(upcoming, other.upcoming, t)!,
      completed: Color.lerp(completed, other.completed, t)!,
      cancelled: Color.lerp(cancelled, other.cancelled, t)!,
      cancelledSoft: Color.lerp(cancelledSoft, other.cancelledSoft, t)!,
      rejected: Color.lerp(rejected, other.rejected, t)!,
      missed: Color.lerp(missed, other.missed, t)!,
      joinAvailable: Color.lerp(joinAvailable, other.joinAvailable, t)!,
      joinUnavailable: Color.lerp(joinUnavailable, other.joinUnavailable, t)!,
      scheduledBackground: Color.lerp(
        scheduledBackground,
        other.scheduledBackground,
        t,
      )!,
      scheduledForeground: Color.lerp(
        scheduledForeground,
        other.scheduledForeground,
        t,
      )!,
      rating: Color.lerp(rating, other.rating, t)!,
    );
  }
}

extension QuranSessionsStatusColorsX on BuildContext {
  /// Session / booking / availability status colors for Quran Sessions.
  QuranSessionsStatusColors get quranSessionsStatus =>
      QuranSessionsStatusColors.of(this);
}
