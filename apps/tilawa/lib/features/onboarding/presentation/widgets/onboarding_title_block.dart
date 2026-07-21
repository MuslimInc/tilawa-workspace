import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Splits a two-line onboarding title into hero + supporting lines.
///
/// Headline sits on the bottom of its slot and subline on the top so short
/// copy stays visually tight while still reserving wrap room for locales.
class OnboardingTitleBlock extends StatelessWidget {
  const OnboardingTitleBlock({
    super.key,
    required this.title,
    required this.lineSpacing,
  });

  final String title;
  final double lineSpacing;

  /// Tight enough for titles; [MeMuslimDesignTokens.textHeightLoose] is for
  /// long body reading and over-inflates reserved title slots.
  static const double _titleLineHeight = 1.25;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final List<String> lines = title.split('\n');
    final String headline = lines.first.trim();
    final String subline = lines.length > 1
        ? lines.sublist(1).join('\n').trim()
        : '';

    final TextStyle headlineStyle =
        theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          height: _titleLineHeight,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          height: _titleLineHeight,
          fontSize: 24,
        );
    final TextStyle sublineStyle =
        theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
          height: _titleLineHeight,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
          height: _titleLineHeight,
          fontSize: 16,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TilawaReservedTextLines(
          text: headline,
          style: headlineStyle,
          maxLines: 2,
          alignment: Alignment.bottomCenter,
        ),
        SizedBox(height: lineSpacing),
        TilawaReservedTextLines(
          text: subline,
          style: sublineStyle,
          maxLines: 2,
          alignment: Alignment.topCenter,
        ),
      ],
    );
  }
}
