import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// In-body page header for long marketing titles and subtitles.
///
/// App bars in this feature stay short; use this under the app bar when a
/// screen needs a hero title (see [TeacherListScreen]).
///
/// Set [compact] on preview surfaces (feature home) to avoid repeating the
/// app bar title with a second hero block.
class QuranSessionsPageHeader extends StatelessWidget {
  const QuranSessionsPageHeader({
    super.key,
    this.title,
    this.subtitle,
    this.compact = false,
  });

  final String? title;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final tokens = theme.tokens;

    if (title == null && subtitle == null) {
      return const SizedBox.shrink();
    }

    final titleStyle = compact
        ? textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          )
        : textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceExtraSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Text(
              title!,
              style: titleStyle,
              textAlign: TextAlign.start,
            ),
          if (title != null && subtitle != null)
            SizedBox(height: tokens.spaceExtraSmall),
          if (subtitle != null)
            Text(
              subtitle!,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
              textAlign: TextAlign.start,
            ),
        ],
      ),
    );
  }
}
