import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Juz row in the Quran hub catalog.
class JuzIndexTile extends StatelessWidget {
  const JuzIndexTile({
    super.key,
    required this.juzNumber,
    required this.onTap,
    this.grouped = false,
  });

  final int juzNumber;
  final VoidCallback onTap;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final MeMuslimDesignTokens tokens = theme.tokens;
    final QuranReaderTheme readerTheme = QuranReaderTheme.of(context);
    final Juz? juz = getJuz(juzNumber);
    if (juz == null) {
      return const SizedBox.shrink();
    }

    final ({int surah, int verse}) start = juz.start;
    final String surahName = getSurahName(start.surah);

    final Widget row = Row(
      children: [
        _CatalogNumberBadge(
          label: juzNumber.toString().padLeft(2, '0'),
        ),
        SizedBox(width: tokens.spaceMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.l10n.juz} $juzNumber',
                style: grouped
                    ? theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      )
                    : readerTheme.surahTileNameTextStyle,
              ),
              SizedBox(height: tokens.spaceExtraSmall),
              Text(
                surahName,
                style: grouped
                    ? theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: tokens.opacityEmphasis,
                        ),
                      )
                    : readerTheme.surahTileMetaTextStyle,
              ),
            ],
          ),
        ),
        Icon(
          TilawaIcons.chevronRight,
          color: colorScheme.onSurfaceVariant,
          size: tokens.iconSizeSmall,
        ),
      ],
    );

    if (grouped) {
      return TilawaInteractiveSurface(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceMedium,
          ),
          child: row,
        ),
      );
    }

    return TilawaCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ),
      backgroundColor: colorScheme.surface,
      borderRadius: tokens.radiusCard,
      child: row,
    );
  }
}

/// Mushaf page row in the Quran hub catalog.
class PageIndexTile extends StatelessWidget {
  const PageIndexTile({
    super.key,
    required this.pageNumber,
    required this.onTap,
    this.grouped = false,
  });

  final int pageNumber;
  final VoidCallback onTap;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final MeMuslimDesignTokens tokens = theme.tokens;
    final QuranReaderTheme readerTheme = QuranReaderTheme.of(context);
    final List<PageSurahEntry> pageData = getPageData(pageNumber);
    final PageSurahEntry first = pageData.first;
    final String surahName = getSurahName(first.surah);

    final Widget row = Row(
      children: [
        _CatalogNumberBadge(
          label: pageNumber.toString().padLeft(3, '0'),
        ),
        SizedBox(width: tokens.spaceMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.l10n.page} $pageNumber',
                style: grouped
                    ? theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      )
                    : readerTheme.surahTileNameTextStyle,
              ),
              SizedBox(height: tokens.spaceExtraSmall),
              Text(
                surahName,
                style: grouped
                    ? theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: tokens.opacityEmphasis,
                        ),
                      )
                    : readerTheme.surahTileMetaTextStyle,
              ),
            ],
          ),
        ),
        Icon(
          TilawaIcons.chevronRight,
          color: colorScheme.onSurfaceVariant,
          size: tokens.iconSizeSmall,
        ),
      ],
    );

    if (grouped) {
      return TilawaInteractiveSurface(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceMedium,
          ),
          child: row,
        ),
      );
    }

    return TilawaCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ),
      backgroundColor: colorScheme.surface,
      borderRadius: tokens.radiusCard,
      child: row,
    );
  }
}

class _CatalogNumberBadge extends StatelessWidget {
  const _CatalogNumberBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final SurahIndexTheme indexTheme = SurahIndexTheme.of(context);
    final QuranReaderTheme readerTheme = QuranReaderTheme.of(context);

    return Container(
      width: indexTheme.tileNumberSize,
      height: indexTheme.tileNumberSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Text(
        label,
        style: readerTheme.pillPageTextStyle.copyWith(
          color: colorScheme.primary,
          fontSize: indexTheme.tileNumberFontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
