import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A single surah row in the Quran catalog.
class SurahIndexTile extends StatelessWidget {
  const SurahIndexTile({
    super.key,
    required this.surahNumber,
    required this.onTap,
    this.grouped = false,
  });

  final int surahNumber;
  final VoidCallback onTap;

  /// Flat row inside [QuranCatalogGroupedList]; raised card in bottom sheets.
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final QuranReaderTheme readerTheme = QuranReaderTheme.of(context);
    final SurahIndexTheme indexTheme = SurahIndexTheme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final MeMuslimDesignTokens tokens = theme.tokens;

    final String arabicName = getSurahNameArabic(surahNumber);
    final String englishName = getSurahName(surahNumber);
    final int verseCount = getVerseCount(surahNumber);

    final Widget row = Row(
      children: [
        Container(
          width: indexTheme.tileNumberSize,
          height: indexTheme.tileNumberSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHigh,
            border: Border.all(
              color: colorScheme.primary.withValues(
                alpha: tokens.opacitySubtle,
              ),
              width: tokens.borderWidthThin,
            ),
          ),
          child: Text(
            surahNumber.toString().padLeft(2, '0'),
            style: readerTheme.pillPageTextStyle.copyWith(
              color: colorScheme.primary,
              fontSize: indexTheme.tileNumberFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: tokens.spaceMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                englishName,
                style: grouped
                    ? theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      )
                    : readerTheme.surahTileNameTextStyle,
              ),
              SizedBox(height: tokens.spaceExtraSmall),
              Row(
                children: [
                  Icon(
                    TilawaIcons.menuBook,
                    size: tokens.iconSizeExtraSmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: tokens.spaceExtraSmall),
                  Text(
                    context.l10n.ayahCount(verseCount),
                    style: grouped
                        ? theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: tokens.opacityEmphasis,
                            ),
                            fontWeight: FontWeight.w500,
                          )
                        : readerTheme.surahTileMetaTextStyle,
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          arabicName,
          style: grouped
              ? theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  height: tokens.textHeightLoose,
                )
              : readerTheme.surahTileArabicNameTextStyle,
        ),
      ],
    );

    if (grouped) {
      return TilawaInteractiveSurface(
        onTap: onTap,
        child: Padding(
          padding: indexTheme.tilePadding,
          child: row,
        ),
      );
    }

    return TilawaCard(
      onTap: onTap,
      padding: indexTheme.tilePadding,
      backgroundColor: colorScheme.surface,
      borderRadius: tokens.radiusCard,
      child: row,
    );
  }
}
