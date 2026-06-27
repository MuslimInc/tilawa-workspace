import 'package:flutter/material.dart';

import 'quran_sessions_theme.dart';

/// Applies [QuranSessionsTheme] to a subtree without replacing app [ColorScheme].
class QuranSessionsThemeScope extends StatelessWidget {
  const QuranSessionsThemeScope({super.key, required this.child});

  final Widget child;

  /// Merges feature extension and tutoring chrome into [parent].
  static ThemeData themed(ThemeData parent) {
    final feature = QuranSessionsTheme.fromTheme(parent);
    final preserved = parent.extensions.values
        .where((ext) => ext is! QuranSessionsTheme)
        .toList(growable: true);
    preserved.add(feature);

    final scheme = parent.colorScheme;

    return parent.copyWith(
      scaffoldBackgroundColor: feature.scaffoldBackground,
      canvasColor: feature.scaffoldBackground,
      appBarTheme: parent.appBarTheme.copyWith(
        backgroundColor: feature.scaffoldBackground,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: feature.screenTitleStyle,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: feature.linkColor),
      ),
      extensions: preserved,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themed(Theme.of(context)),
      child: child,
    );
  }
}
