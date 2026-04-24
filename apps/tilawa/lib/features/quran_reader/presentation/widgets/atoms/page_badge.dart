import 'package:flutter/material.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';

/// A small chip widget showing the page number in the Quran Reader navigation.
class PageBadge extends StatelessWidget {
  const PageBadge({
    super.key,
    required this.pageNumber,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.textStyle,
  });

  final int pageNumber;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final QuranReaderTheme readerTheme = QuranReaderTheme.of(context);
    final PageNavigationBarTheme navTheme = PageNavigationBarTheme.of(context);

    final Color readerPrimary = readerTheme.primaryColor;

    final Color effectiveBg =
        backgroundColor ??
        readerPrimary.withValues(
          alpha: isDark
              ? navTheme.badgeBgAlphaDark
              : navTheme.badgeBgAlphaLight,
        );
    final Color effectiveFg = foregroundColor ?? readerPrimary;
    final Color effectiveBorder =
        borderColor ??
        readerPrimary.withValues(
          alpha: isDark
              ? navTheme.badgeBorderAlphaDark
              : navTheme.badgeBorderAlphaLight,
        );

    return Container(
      padding: navTheme.badgePadding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(navTheme.badgeRadius),
        border: Border.all(color: effectiveBorder),
      ),
      child: Text(
        '$pageNumber',
        style: (textStyle ?? readerTheme.cardPageBadgeTextStyle).copyWith(
          color: effectiveFg,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
