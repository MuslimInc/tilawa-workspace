import 'package:flutter/material.dart';

import '../theme/quran_sessions_theme.dart';

/// Section title row used across Quran Sessions student screens.
class QuranSessionsSectionHeader extends StatelessWidget {
  const QuranSessionsSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;

    return Row(
      children: [
        Expanded(
          child: Text(title, style: feature.sectionTitleStyle),
        ),
        ?trailing,
      ],
    );
  }
}
