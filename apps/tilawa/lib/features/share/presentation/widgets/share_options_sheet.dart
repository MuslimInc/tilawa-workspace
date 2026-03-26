import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart';

import 'package:tilawa/core/extensions.dart';

/// Bottom sheet presenting share options with Quran-focused visual context.
class ShareOptionsSheet extends StatelessWidget {
  const ShareOptionsSheet({
    super.key,
    required this.surahNumber,
    required this.pageNumber,
    required this.onShareScreenshot,
    required this.onShareAudioClip,
  });

  final int surahNumber;
  final int pageNumber;
  final VoidCallback onShareScreenshot;
  final VoidCallback onShareAudioClip;

  String get _arabicSurahName => getSurahNameArabic(surahNumber);
  String get _englishSurahName => getSurahNameEnglish(surahNumber);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _ShareSheetColors.gold.withValues(alpha: 0.22),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _ShareSheetColors.deepGreen,
                _ShareSheetColors.forestGreen,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                const Positioned(
                  top: -120,
                  right: -60,
                  child: _AmbientOrb(
                    size: 220,
                    color: _ShareSheetColors.mint,
                    opacity: 0.08,
                  ),
                ),
                const Positioned(
                  bottom: -90,
                  left: -30,
                  child: _AmbientOrb(
                    size: 180,
                    color: _ShareSheetColors.gold,
                    opacity: 0.08,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SheetHandle(),
                      _ShareHeader(
                        arabicSurahName: _arabicSurahName,
                        englishSurahName: _englishSurahName,
                        pageNumber: pageNumber,
                      ),
                      const SizedBox(height: 18),
                      _ShareOptionCard(
                        icon: Icons.image_rounded,
                        title: context.l10n.shareScreenshot,
                        description: context.l10n.shareScreenshotDescription,
                        accent: _ShareSheetColors.gold,
                        onTap: () {
                          Navigator.of(context).pop();
                          onShareScreenshot();
                        },
                      ),
                      const SizedBox(height: 12),
                      _ShareOptionCard(
                        icon: Icons.play_circle_fill_rounded,
                        title: context.l10n.shareAudioClip,
                        description: context.l10n.shareAudioClipDescription,
                        accent: _ShareSheetColors.mint,
                        onTap: () {
                          Navigator.of(context).pop();
                          onShareAudioClip();
                        },
                      ),
                    ],
                  ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        color: Colors.white.withValues(alpha: 0.07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: _ShareSheetColors.gold.withValues(alpha: 0.14),
                  border: Border.all(
                    color: _ShareSheetColors.gold.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 16,
                      color: _ShareSheetColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tilawa',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _ShareSheetColors.cream,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: _ShareSheetColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$pageNumber',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            arabicSurahName,
            style: GoogleFonts.amiri(
              fontSize: 30,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            englishSurahName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.shareSheetSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOptionCard extends StatelessWidget {
  const _ShareOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.92),
                        accent.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: _ShareSheetColors.deepGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.68),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_outward_rounded, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _ShareSheetColors {
  static const Color deepGreen = Color(0xFF0D3933);
  static const Color forestGreen = Color(0xFF165147);
  static const Color gold = Color(0xFFE1C17B);
  static const Color mint = Color(0xFF8FDFC0);
  static const Color cream = Color(0xFFF7F1E1);
}
