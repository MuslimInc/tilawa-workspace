import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Bottom sheet presenting share options using the Tilawa UI kit.
class ShareOptionsSheet extends StatelessWidget {
  const ShareOptionsSheet({
    super.key,
    required this.surahNumber,
    required this.pageNumber,
    required this.onShareScreenshot,
    required this.onShareVideoReel,
  });

  final int surahNumber;
  final int pageNumber;
  final VoidCallback onShareScreenshot;
  final VoidCallback onShareVideoReel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final radius = tokens.radiusExtraLarge + tokens.spaceSmall;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceMedium,
          tokens.spaceSmall,
          tokens.spaceMedium,
          tokens.spaceMedium,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(
                alpha: tokens.opacitySubtle,
              ),
              width: tokens.borderWidthThin,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(
                  alpha: tokens.opacitySubtle,
                ),
                blurRadius: tokens.blurShadow,
                offset: tokens.shadowOffsetMedium,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLarge,
              tokens.spaceSmall,
              tokens.spaceLarge,
              tokens.spaceLarge,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TilawaSheetHandle(),
                SizedBox(height: tokens.spaceSmall),
                _ShareHeader(
                  arabicSurahName: getSurahNameArabic(surahNumber),
                  englishSurahName: getSurahNameEnglish(surahNumber),
                  pageNumber: pageNumber,
                ),
                SizedBox(height: tokens.spaceMedium),
                _ShareOptionCard(
                  icon: Icons.image_rounded,
                  title: context.l10n.shareScreenshot,
                  description: context.l10n.shareScreenshotDescription,
                  onTap: onShareScreenshot,
                ),
                SizedBox(height: tokens.spaceSmall),
                _ShareOptionCard(
                  icon: Icons.movie_creation_outlined,
                  title: context.l10n.shareModeReel,
                  description: context.l10n.shareAudioClipDescription,
                  onTap: onShareVideoReel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareHeader extends StatelessWidget {
  const _ShareHeader({
    required this.arabicSurahName,
    required this.englishSurahName,
    required this.pageNumber,
  });

  final String arabicSurahName;
  final String englishSurahName;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const MetadataChip(
              icon: Icons.auto_stories_rounded,
              label: 'Tilawa',
            ),
            const Spacer(),
            MetadataChip(icon: Icons.menu_book_rounded, label: '$pageNumber'),
          ],
        ),
        SizedBox(height: tokens.spaceMedium),
        Text(
          arabicSurahName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        SizedBox(height: tokens.spaceExtraSmall),
        Text(
          englishSurahName,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        Text(
          context.l10n.shareSheetSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ShareOptionCard extends StatelessWidget {
  const _ShareOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final accent = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            color: theme.colorScheme.surface.withValues(
              alpha: tokens.opacitySubtle,
            ),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(
                alpha: tokens.opacitySubtle,
              ),
              width: tokens.borderWidthThin,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceMedium),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tokens.radiusMedium),
                    color: accent.withValues(alpha: tokens.opacitySubtle),
                  ),
                  child: Icon(icon, color: accent, size: tokens.iconSizeLarge),
                ),
                SizedBox(width: tokens.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: tokens.spaceSmall),
                Icon(
                  Icons.arrow_outward_rounded,
                  color: accent,
                  size: tokens.iconSizeSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
