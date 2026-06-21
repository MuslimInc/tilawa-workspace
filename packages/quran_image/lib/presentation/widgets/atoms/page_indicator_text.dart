import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../l10n/quran_image_localizations.dart';

/// Atomic component for displaying the current page number.
///
/// This is a simple text widget styled according to design tokens.
class PageIndicatorText extends StatelessWidget {
  final int pageNumber;
  final int totalPages;
  final double screenWidth;

  const PageIndicatorText({
    super.key,
    required this.pageNumber,
    required this.totalPages,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final l10n = QuranImageLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
        borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
      ),
      child: Text(
        l10n.page(pageNumber.toString()),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
