import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A single surah row in the Quran catalog (Behance-style raised card).
class SurahIndexTile extends StatelessWidget {
  const SurahIndexTile({
    super.key,
    required this.surahNumber,
    required this.onTap,
  });

  final int surahNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final QuranReaderTheme readerTheme = QuranReaderTheme.of(context);
    final SurahIndexTheme indexTheme = SurahIndexTheme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaDesignTokens tokens = theme.tokens;

    final String arabicName = getSurahNameArabic(surahNumber);
    final String englishName = getSurahName(surahNumber);
    final int verseCount = getVerseCount(surahNumber);

    return TilawaCard(
      onTap: onTap,
      padding: indexTheme.tilePadding,
      backgroundColor: colorScheme.surface,
      borderRadius: tokens.radiusCard,
      child: Row(
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
                  style: readerTheme.surahTileNameTextStyle,
                ),
                SizedBox(height: tokens.spaceExtraSmall),
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: tokens.iconSizeExtraSmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: tokens.spaceExtraSmall),
                    Text(
                      context.l10n.ayahCount(verseCount),
                      style: readerTheme.surahTileMetaTextStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            arabicName,
            style: readerTheme.surahTileArabicNameTextStyle,
          ),
        ],
      ),
    );
  }
}
