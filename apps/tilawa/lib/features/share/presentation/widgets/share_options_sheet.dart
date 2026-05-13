import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Bottom sheet presenting share options using the Tilawa UI kit.
class ShareOptionsSheet extends StatefulWidget {
  const ShareOptionsSheet({
    super.key,
    required this.surahNumber,
    required this.pageNumber,
    required this.onShareScreenshot,
    required this.onShareVideoReel,
  });

  final int surahNumber;
  final int pageNumber;
  final void Function(int selectedSurah) onShareScreenshot;
  final void Function(int selectedSurah) onShareVideoReel;

  @override
  State<ShareOptionsSheet> createState() => _ShareOptionsSheetState();
}

class _ShareOptionsSheetState extends State<ShareOptionsSheet> {
  late int _selectedSurah;
  late List<int> _uniqueSurahs;

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.surahNumber;
    _uniqueSurahs = getPageData(
      widget.pageNumber,
    ).map((e) => e.surah).toSet().toList();

    // If the provided surahNumber is not on the page (sanity check), pick the first one.
    if (!_uniqueSurahs.contains(_selectedSurah) && _uniqueSurahs.isNotEmpty) {
      _selectedSurah = _uniqueSurahs.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final radius = tokens.radiusExtraLarge + tokens.spaceSmall;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceSmall,
          tokens.spaceLarge,
          tokens.spaceLarge,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TilawaSheetHandle(),
              SizedBox(height: tokens.spaceSmall),
              _ShareHeader(
                selectedSurah: _selectedSurah,
                uniqueSurahs: _uniqueSurahs,
                pageNumber: widget.pageNumber,
                onSurahChanged: (surah) {
                  setState(() {
                    _selectedSurah = surah;
                  });
                },
              ),
              SizedBox(height: tokens.spaceMedium),
              _ShareOptionCard(
                icon: Icons.image_rounded,
                title: context.l10n.shareScreenshot,
                description: context.l10n.shareScreenshotDescription,
                onTap: () => widget.onShareScreenshot(_selectedSurah),
              ),
              SizedBox(height: tokens.spaceSmall),
              _ShareOptionCard(
                icon: Icons.movie_creation_outlined,
                title: context.l10n.shareModeReel,
                description: context.l10n.shareAudioClipDescription,
                onTap: () => widget.onShareVideoReel(_selectedSurah),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareHeader extends StatelessWidget {
  const _ShareHeader({
    required this.selectedSurah,
    required this.uniqueSurahs,
    required this.pageNumber,
    required this.onSurahChanged,
  });

  final int selectedSurah;
  final List<int> uniqueSurahs;
  final int pageNumber;
  final ValueChanged<int> onSurahChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isArabic = context.l10n.localeName == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const TilawaMetadataChip(
              icon: Icons.auto_stories_rounded,
              label: 'Tilawa',
            ),
            const Spacer(),
            TilawaMetadataChip(
              icon: Icons.menu_book_rounded,
              label: '$pageNumber',
            ),
          ],
        ),
        SizedBox(height: tokens.spaceMedium),
        if (uniqueSurahs.length > 1) ...[
          Text(
            context.l10n.selectSurahToShare,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: tokens.spaceSmall,
              children: uniqueSurahs.map((surah) {
                final isSelected = surah == selectedSurah;
                return ChoiceChip(
                  label: Text(
                    isArabic
                        ? getSurahNameArabic(surah)
                        : getSurahNameEnglish(surah),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onSurahChanged(surah);
                  },
                );
              }).toList(),
            ),
          ),
          SizedBox(height: tokens.spaceMedium),
        ],
        Text(
          isArabic
              ? getSurahNameArabic(selectedSurah)
              : getSurahNameEnglish(selectedSurah),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        SizedBox(height: tokens.spaceExtraSmall),
        Text(
          getSurahNameEnglish(selectedSurah),
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
