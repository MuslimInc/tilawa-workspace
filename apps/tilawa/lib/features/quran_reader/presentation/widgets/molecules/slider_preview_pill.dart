import 'package:flutter/material.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/atoms/page_badge.dart';

/// A floating preview Molecule for the Quran Navigation slider.
class SliderPreviewPill extends StatelessWidget {
  const SliderPreviewPill({
    super.key,
    required this.width,
    required this.surahName,
    required this.pageNumber,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.isDark,
  });

  final double width;
  final String surahName;
  final int pageNumber;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color mutedTextColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final navTheme = PageNavigationBarTheme.of(context);
    final readerTheme = QuranReaderTheme.of(context);

    final Color pillBorder = primaryColor.withValues(
      alpha: isDark
          ? navTheme.previewPillBorderAlphaDark
          : navTheme.previewPillBorderAlphaLight,
    );

    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: navTheme.previewPillPadding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(navTheme.previewPillRadius),
          border: Border.all(color: pillBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(
                alpha: isDark
                    ? navTheme.previewPillShadowAlphaDark
                    : navTheme.previewPillShadowAlphaLight,
              ),
              blurRadius: 18,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  surahName,
                  textAlign: TextAlign.center,
                  style: readerTheme.pillSurahTextStyle.copyWith(
                    color: textColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            PageBadge(
              pageNumber: pageNumber,
              backgroundColor: primaryColor.withValues(
                alpha: isDark
                    ? navTheme.badgeBgAlphaDark
                    : navTheme.badgeBgAlphaLight,
              ),
              foregroundColor: primaryColor,
              borderColor: Colors.transparent,
              textStyle: readerTheme.pillPageTextStyle,
            ),
          ],
        ),
      ),
    );
  }
}
