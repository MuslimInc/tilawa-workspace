import 'package:flutter/material.dart';

import 'quran_sessions_status_colors.dart';

/// Injects feature-specific [QuranSessionsStatusColors] into a subtree.
///
/// All chrome, layout, typography, spacing, radius, and neutral/brand colors
/// come from the global MeMuslim UI Kit theme. This scope only adds the
/// session / booking / availability status palette the feature genuinely owns
/// — it does not override the scaffold background, app bar, or text buttons.
class QuranSessionsThemeScope extends StatelessWidget {
  const QuranSessionsThemeScope({super.key, required this.child});

  final Widget child;

  /// Merges [QuranSessionsStatusColors] into [parent] without other overrides.
  static ThemeData themed(ThemeData parent) {
    final statusColors = QuranSessionsStatusColors.fromScheme(
      parent.colorScheme,
    );
    final preserved =
        parent.extensions.values
            .where((ext) => ext is! QuranSessionsStatusColors)
            .toList(growable: true)
          ..add(statusColors);

    return parent.copyWith(extensions: preserved);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themed(Theme.of(context)),
      child: child,
    );
  }
}
