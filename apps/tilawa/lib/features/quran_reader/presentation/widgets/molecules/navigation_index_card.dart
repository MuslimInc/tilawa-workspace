import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/atoms/page_badge.dart';

/// A card-based Molecule for navigating through the Quran index.
class NavigationIndexCard extends StatelessWidget {
  const NavigationIndexCard({
    super.key,
    required this.pageNumber,
    required this.surahNumber,
    required this.surahName,
    required this.juzNumber,
    required this.hizbLabel,
    required this.primaryColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.surfaceColor,
    required this.outlineColor,
    required this.isDark,
    required this.onTap,
  });

  final int pageNumber;
  final int surahNumber;
  final String surahName;
  final int juzNumber;
  final String hizbLabel;
  final Color primaryColor;
  final Color textColor;
  final Color mutedTextColor;
  final Color surfaceColor;
  final Color outlineColor;
  final bool isDark;
  final VoidCallback onTap;

  String _buildContextSummary(BuildContext context) {
    final StringBuffer buffer = StringBuffer()
      ..write('${context.l10n.juzPart} $juzNumber');

    if (hizbLabel.isNotEmpty) {
      buffer.write(' • $hizbLabel');
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final navTheme = PageNavigationBarTheme.of(context);
    final readerTheme = QuranReaderTheme.of(context);
    final Color cardColor = surfaceColor.withValues(alpha: isDark ? 0.4 : 0.7);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(navTheme.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(navTheme.cardRadius),
        child: Ink(
          padding: navTheme.cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(navTheme.cardRadius),
            border: Border.all(
              color: outlineColor.withValues(alpha: navTheme.cardBorderAlpha),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              _buildTopRow(context, readerTheme),
              _buildBottomRow(context, readerTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context, QuranReaderTheme readerTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 10,
      children: [
        PageBadge(
          pageNumber: pageNumber,
          textStyle: readerTheme.cardPageBadgeTextStyle,
        ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              surahName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context, QuranReaderTheme readerTheme) {
    return Text(
      _buildContextSummary(context),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: readerTheme.cardContextSummaryTextStyle.copyWith(
        color: mutedTextColor,
      ),
    );
  }
}
