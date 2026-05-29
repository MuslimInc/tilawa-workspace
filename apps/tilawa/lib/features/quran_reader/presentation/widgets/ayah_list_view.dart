import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';

class AyahListView extends StatelessWidget {
  const AyahListView({
    super.key,
    required this.surah,
    required this.settings,
    this.scrollController,
    this.onAyahTap,
    this.onAyahLongPress,
  });

  final SurahContentEntity surah;
  final ReaderSettingsEntity settings;
  final ScrollController? scrollController;
  final void Function(AyahEntity)? onAyahTap;
  final void Function(AyahEntity)? onAyahLongPress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

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
              onTap: () => onAyahTap?.call(ayah),
              onLongPress: () => onAyahLongPress?.call(ayah),
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
    final tokens = context.tokens;

    return Container(
      margin: EdgeInsets.all(tokens.spaceLarge),
      padding: EdgeInsets.all(tokens.spaceExtraLarge),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
      ),
      child: Column(
        children: [
          Text(
            surah.name,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            surah.nameEnglish,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
          Text(
            surah.nameTranslation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: tokens.spaceMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip(
                label: surah.isMeccan
                    ? context.l10n.meccan
                    : context.l10n.medinan,
                theme: theme,
              ),
              SizedBox(width: tokens.spaceMedium),
              _InfoChip(
                label: context.l10n.ayahCount(surah.numberOfAyahs),
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceExtraSmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimary,
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
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraLarge),
      child: Center(
        child: Text(
          BasmalaEntity.text,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class AyahWidget extends StatelessWidget {
  const AyahWidget({
    super.key,
    required this.ayah,
    required this.settings,
    this.onTap,
    this.onLongPress,
  });

  final AyahEntity ayah;
  final ReaderSettingsEntity settings;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = context.tokens;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLarge,
          vertical: tokens.spaceMedium,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                ayah.text,
                style: TextStyle(
                  fontSize: settings.fontSize,
                  height: settings.lineHeight,
                  fontFamily: settings.fontFamily,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (settings.showTranslation && ayah.translation != null) ...[
              SizedBox(height: tokens.spaceMedium),
              Text(
                ayah.translation!,
                style: TextStyle(
                  fontSize: settings.translationFontSize * 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.left,
              ),
            ],
            if (ayah.sajda ?? false)
              Padding(
                padding: EdgeInsets.only(top: tokens.spaceSmall),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: tokens.iconSizeSmall,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: tokens.spaceExtraSmall),
                    Text(
                      context.l10n.sajda,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
