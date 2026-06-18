import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/shared/widgets/kaaba_icon.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';

class AyahListView extends StatelessWidget {
  const AyahListView({
    super.key,
    required this.surah,
    required this.settings,
    this.scrollController,
    this.onAyahPlay,
    this.onAyahBookmark,
    this.onAyahShare,
  });

  final SurahContentEntity surah;
  final ReaderSettingsEntity settings;
  final ScrollController? scrollController;
  final void Function(AyahEntity ayah)? onAyahPlay;
  final void Function(AyahEntity ayah)? onAyahBookmark;
  final void Function(AyahEntity ayah)? onAyahShare;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = context.tokens;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(child: SurahHeaderWidget(surah: surah)),
        if (surah.number != 1 && surah.number != 9)
          const SliverToBoxAdapter(child: BasmalaWidget()),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final AyahEntity ayah = surah.ayahs[index];
            return AyahWidget(
              ayah: ayah,
              settings: settings,
              onPlay: onAyahPlay == null ? null : () => onAyahPlay!(ayah),
              onBookmark:
                  onAyahBookmark == null ? null : () => onAyahBookmark!(ayah),
              onShare: onAyahShare == null ? null : () => onAyahShare!(ayah),
            );
          }, childCount: surah.ayahs.length),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: tokens.playerCollapsedHeight + tokens.spaceExtraLarge,
          ),
        ),
      ],
    );
  }
}

class SurahHeaderWidget extends StatelessWidget {
  const SurahHeaderWidget({super.key, required this.surah});

  final SurahContentEntity surah;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final TilawaHomeDashboardCardTokens cardTokens =
        theme.componentTokens.homeDashboardCard;
    final Color foreground = cardTokens.foregroundColor;
    final Color mutedForeground = foreground.withValues(alpha: 0.78);
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);
    final bool showHeaderBasmala = surah.number == 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceMedium,
        tokens.spaceLarge,
        tokens.spaceSmall,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              cardTokens.gradientStart,
              cardTokens.gradientEnd,
            ],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.all(tokens.spaceLarge),
              child: Column(
                children: [
                  Text(
                    surah.nameEnglish,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  Text(
                    surah.nameTranslation,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  Text(
                    context.l10n.ayahCount(surah.numberOfAyahs),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showHeaderBasmala) ...[
                    SizedBox(height: tokens.spaceMedium),
                    Text(
                      BasmalaEntity.text,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            PositionedDirectional(
              end: tokens.spaceSmall,
              bottom: tokens.spaceSmall,
              child: const IgnorePointer(
                child: KaabaIcon(
                  size: KaabaAssets.surahHeaderSize,
                  opacity: 0.32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BasmalaWidget extends StatelessWidget {
  const BasmalaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        tokens.spaceMedium,
      ),
      child: Text(
        BasmalaEntity.text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          height: 1.8,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class AyahWidget extends StatelessWidget {
  const AyahWidget({
    super.key,
    required this.ayah,
    required this.settings,
    this.onPlay,
    this.onBookmark,
    this.onShare,
  });

  final AyahEntity ayah;
  final ReaderSettingsEntity settings;
  final VoidCallback? onPlay;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: tokens.spaceMedium),
          Text(
            '${ayah.surahNumber}:${ayah.numberInSurah}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              ayah.text,
              style: TextStyle(
                fontSize: settings.fontSize,
                height: settings.lineHeight,
                fontFamily: settings.fontFamily,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (settings.showTranslation && ayah.translation != null) ...[
            SizedBox(height: tokens.spaceMedium),
            Text(
              ayah.translation!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
          SizedBox(height: tokens.spaceMedium),
          Row(
            children: [
              _AyahActionButton(
                icon: Icons.play_arrow_rounded,
                label: context.l10n.playAyah,
                onTap: onPlay,
              ),
              SizedBox(width: tokens.spaceMedium),
              _AyahActionButton(
                icon: Icons.bookmark_border_rounded,
                label: context.l10n.addBookmark,
                onTap: onBookmark,
              ),
              SizedBox(width: tokens.spaceMedium),
              _AyahActionButton(
                icon: Icons.ios_share_rounded,
                label: context.l10n.shareAyah,
                onTap: onShare,
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMedium),
          TilawaDivider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

class _AyahActionButton extends StatelessWidget {
  const _AyahActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TilawaDesignTokens tokens = Theme.of(context).tokens;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceExtraSmall),
          child: Icon(
            icon,
            size: tokens.iconSizeSmall,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
