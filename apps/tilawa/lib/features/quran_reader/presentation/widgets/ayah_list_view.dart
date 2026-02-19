import 'package:flutter/material.dart';

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
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // Surah header
        SliverToBoxAdapter(child: SurahHeaderWidget(surah: surah)),

        // Basmala (if not Al-Fatiha or At-Tawba)
        if (surah.number != 1 && surah.number != 9)
          const SliverToBoxAdapter(child: BasmalaWidget()),

        // Ayahs
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

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
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

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Surah name in Arabic
          Text(
            surah.name,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(height: 8),
          // English name and translation
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
          const SizedBox(height: 12),
          // Surah info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip(label: surah.revelationType, theme: theme),
              const SizedBox(width: 12),
              _InfoChip(label: '${surah.numberOfAyahs} Ayahs', theme: theme),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          BasmalaEntity.text,
          style: theme.textTheme.headlineSmall?.copyWith(fontFamily: 'Amiri'),
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

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ayah number badge removed as it is handled by the font

            // Arabic text
            Builder(
              builder: (context) {
                print(
                  'Ayah ${ayah.surahNumber}:${ayah.numberInSurah} text: "${ayah.text}"',
                );
                print(
                  'Ayah ${ayah.surahNumber}:${ayah.numberInSurah} runes: ${ayah.text.runes.toList()}',
                );
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    ayah.text,
                    style: TextStyle(
                      fontSize: settings.fontSize,
                      height: settings.lineHeight,
                      fontFamily: settings.fontFamily,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                );
              },
            ),

            // Translation
            if (settings.showTranslation && ayah.translation != null) ...[
              const SizedBox(height: 12),
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

            // Sajda indicator
            if (ayah.sajda ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sajda',
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
