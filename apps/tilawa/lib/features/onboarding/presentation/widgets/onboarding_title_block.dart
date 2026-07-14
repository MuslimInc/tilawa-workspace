import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Splits a two-line onboarding title into hero + supporting lines.
///
/// Each line uses a reserved slot so slide / locale changes do not shift
/// description or thumb-reach chrome.
class OnboardingTitleBlock extends StatelessWidget {
  const OnboardingTitleBlock({
    super.key,
    required this.title,
    required this.lineSpacing,
  });

  final String title;
  final double lineSpacing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final List<String> lines = title.split('\n');
    final String headline = lines.first.trim();
    final String subline = lines.length > 1
        ? lines.sublist(1).join('\n').trim()
        : '';

    final TextStyle headlineStyle =
        theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          height: tokens.textHeightLoose,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          height: tokens.textHeightLoose,
          fontSize: 22,
        );
    final TextStyle sublineStyle =
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          height: tokens.textHeightLoose,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          height: tokens.textHeightLoose,
          fontSize: 16,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TilawaReservedTextLines(
          text: headline,
          style: headlineStyle,
          maxLines: 2,
        ),
        SizedBox(height: lineSpacing),
        TilawaReservedTextLines(
          text: subline,
          style: sublineStyle,
          maxLines: 2,
        ),
      ],
    );
  }
}
