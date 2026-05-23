import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Splits a two-line onboarding title into hero + supporting lines.
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
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final List<String> lines = title.split('\n');
    final String headline = lines.first.trim();
    final String? subline = lines.length > 1
        ? lines.sublist(1).join('\n').trim()
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          headline,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            height: tokens.textHeightLoose,
          ),
        ),
        if (subline != null && subline.isNotEmpty) ...[
          SizedBox(height: lineSpacing),
          Text(
            subline,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: tokens.textHeightLoose,
            ),
          ),
        ],
      ],
    );
  }
}
