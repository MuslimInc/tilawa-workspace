import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart';
// ignore: implementation_imports
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../utils/reel_page_specs.dart';

final ValueNotifier<bool> _hiddenOverlaysListenable = ValueNotifier<bool>(
  false,
);

/// A Quran-focused 9:16 canvas used for reel generation.
class ReelContentRenderer extends StatelessWidget {
  const ReelContentRenderer({
    super.key,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    this.reciterName,
    this.pageSpecs,
  });

  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final String? reciterName;
  final List<ReelPageSpec>? pageSpecs;

  @override
  Widget build(BuildContext context) {
    final List<ReelPageSpec> effectivePageSpecs =
        pageSpecs ??
        buildReelPageSpecs(
          surahNumber: surahNumber,
          fromAyah: fromAyah,
          toAyah: toAyah,
        );

    if (effectivePageSpecs.length == 1) {
      return ReelContentPage(
        surahNumber: surahNumber,
        pageSpec: effectivePageSpecs.single,
        pageIndex: 0,
        totalPages: 1,
        reciterName: reciterName,
      );
    }

    return SizedBox(
      width: 1080,
      height: 1920,
      child: PageView.builder(
        itemCount: effectivePageSpecs.length,
        itemBuilder: (context, index) {
          return ReelContentPage(
            surahNumber: surahNumber,
            pageSpec: effectivePageSpecs[index],
            pageIndex: index,
            totalPages: effectivePageSpecs.length,
            reciterName: reciterName,
          );
        },
      ),
    );
  }
}

class ReelContentPage extends StatelessWidget {
  const ReelContentPage({
    super.key,
    required this.surahNumber,
    required this.pageSpec,
    required this.pageIndex,
    required this.totalPages,
    this.reciterName,
  });

  final int surahNumber;
  final ReelPageSpec pageSpec;
  final int pageIndex;
  final int totalPages;
  final String? reciterName;

  String get _arabicSurahName => getSurahNameArabic(surahNumber);
  String get _englishSurahName => getSurahNameEnglish(surahNumber);

  String get _ayahRangeLabel => pageSpec.fromAyah == pageSpec.toAyah
      ? 'آية ${pageSpec.fromAyah}'
      : 'الآيات ${pageSpec.fromAyah} - ${pageSpec.toAyah}';

  String get _mushafPageLabel => totalPages == 1
      ? 'صفحة المصحف ${pageSpec.pageNumber}'
      : 'صفحة المصحف ${pageSpec.pageNumber} • ${pageIndex + 1}/$totalPages';

  @override
  Widget build(BuildContext context) {
    final normalizedReciterName = reciterName?.trim();

    return SizedBox(
      width: 1080,
      height: 1920,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _ReelPalette.deepGreen,
              _ReelPalette.forestGreen,
              _ReelPalette.tealGreen,
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -140,
              right: -60,
              child: TilawaAmbientOrb(
                size: 320,
                color: _ReelPalette.mint,
                opacity: 0.12,
              ),
            ),
            const Positioned(
              bottom: -120,
              left: -50,
              child: TilawaAmbientOrb(
                size: 260,
                color: _ReelPalette.gold,
                opacity: 0.12,
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: _ReelPalette.gold.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 96, 72, 88),
              child: Column(
                children: [
                  const _BrandSeal(),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(56, 56, 56, 48),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(48),
                        border: Border.all(
                          color: _ReelPalette.gold.withValues(alpha: 0.58),
                          width: 2,
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _ReelPalette.parchment,
                            _ReelPalette.warmParchment,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _SurahHero(
                            arabicSurahName: _arabicSurahName,
                            englishSurahName: _englishSurahName,
                            surahNumber: surahNumber,
                            ayahRangeLabel: _ayahRangeLabel,
                            mushafPageLabel: _mushafPageLabel,
                            reciterName: normalizedReciterName,
                          ),
                          const SizedBox(height: 32),
                          Expanded(
                            child: _ReelMushafPage(
                              surahNumber: surahNumber,
                              pageSpec: pageSpec,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _ReelFooter(reciterName: normalizedReciterName),
                        ],
                      ),
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

class _ReelMushafPage extends StatefulWidget {
  const _ReelMushafPage({required this.surahNumber, required this.pageSpec});

  final int surahNumber;
  final ReelPageSpec pageSpec;

  @override
  State<_ReelMushafPage> createState() => _ReelMushafPageState();
}

class _ReelMushafPageState extends State<_ReelMushafPage> {
  // Stable callback reference — PageContent.didUpdateWidget checks
  // verseBackgroundColor with reference equality (!=). A new closure on every
  // build() always compares unequal, which forces a full snapshot invalidation
  // cycle (disable → re-rasterize → enable) on every parent rebuild.
  late Color? Function(int, int) _verseBackgroundColor;

  @override
  void initState() {
    super.initState();
    _verseBackgroundColor = _buildVerseBackgroundColor();
  }

  @override
  void didUpdateWidget(_ReelMushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber ||
        oldWidget.pageSpec.fromAyah != widget.pageSpec.fromAyah ||
        oldWidget.pageSpec.toAyah != widget.pageSpec.toAyah) {
      _verseBackgroundColor = _buildVerseBackgroundColor();
    }
  }

  Color? Function(int, int) _buildVerseBackgroundColor() {
    final int surahNumber = widget.surahNumber;
    final int fromAyah = widget.pageSpec.fromAyah;
    final int toAyah = widget.pageSpec.toAyah;
    return (int currentSurah, int verseNumber) {
      if (currentSurah != surahNumber ||
          verseNumber < fromAyah ||
          verseNumber > toAyah) {
        return null;
      }
      return _ReelPalette.gold.withValues(alpha: 0.24);
    };
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: Colors.white.withValues(alpha: 0.42),
        border: Border.all(color: _ReelPalette.gold.withValues(alpha: 0.26)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFFFF8ED)),
          child: MediaQuery(
            data: mediaQuery.copyWith(
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: PageContent(
                pageNumber: widget.pageSpec.pageNumber,
                textColor: _ReelPalette.ink.withValues(alpha: 0.96),
                pageBackgroundColor: const Color(0xFFFFF8ED),
                verseBackgroundColor: _verseBackgroundColor,
                uiTextDirection: TextDirection.rtl,
                showOverlaysListenable: _hiddenOverlaysListenable,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandSeal extends StatelessWidget {
  const _BrandSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _ReelPalette.gold.withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: _ReelPalette.gold,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Tilawa',
            style: GoogleFonts.alexandria(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _ReelPalette.cream,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahHero extends StatelessWidget {
  const _SurahHero({
    required this.arabicSurahName,
    required this.englishSurahName,
    required this.surahNumber,
    required this.ayahRangeLabel,
    required this.mushafPageLabel,
    required this.reciterName,
  });

  final String arabicSurahName;
  final String englishSurahName;
  final int surahNumber;
  final String ayahRangeLabel;
  final String mushafPageLabel;
  final String? reciterName;

  static const SurahHeaderGlyphProvider _glyphProvider =
      QcfSurahHeaderGlyphProvider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.72),
            Colors.white.withValues(alpha: 0.42),
          ],
        ),
        border: Border.all(color: _ReelPalette.gold.withValues(alpha: 0.36)),
      ),
      child: Column(
        children: [
          Text(
            _glyphProvider.glyphForSurah(surahNumber),
            style: const TextStyle(
              fontFamily: SurahHeaderBannerConstants.fontFamily,
              package: SurahHeaderBannerConstants.packageName,
              fontSize: 78,
              color: _ReelPalette.deepGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            arabicSurahName,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 46,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: _ReelPalette.deepGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            englishSurahName.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.alexandria(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
              color: _ReelPalette.deepGreen.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                icon: Icons.format_list_numbered_rounded,
                label: ayahRangeLabel,
              ),
              _HeroPill(icon: Icons.menu_book_rounded, label: mushafPageLabel),
              if (reciterName != null && reciterName!.isNotEmpty)
                _HeroPill(
                  icon: Icons.multitrack_audio_rounded,
                  label: reciterName!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: _ReelPalette.deepGreen.withValues(alpha: 0.08),
          border: Border.all(
            color: _ReelPalette.deepGreen.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _ReelPalette.gold),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alexandria(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _ReelPalette.deepGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelFooter extends StatelessWidget {
  const _ReelFooter({required this.reciterName});

  final String? reciterName;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        const _FooterPill(icon: Icons.auto_stories_rounded, label: 'Tilawa'),
        if (reciterName != null && reciterName!.isNotEmpty)
          _FooterPill(
            icon: Icons.multitrack_audio_rounded,
            label: reciterName!,
          ),
      ],
    );
  }
}

class _FooterPill extends StatelessWidget {
  const _FooterPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: _ReelPalette.deepGreen.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _ReelPalette.gold),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alexandria(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _ReelPalette.deepGreen.withValues(alpha: 0.78),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class _ReelPalette {
  static const Color deepGreen = Color(0xFF0B342E);
  static const Color forestGreen = Color(0xFF145247);
  static const Color tealGreen = Color(0xFF1E6558);
  static const Color gold = Color(0xFFE1C17B);
  static const Color mint = Color(0xFF8FDFC0);
  static const Color cream = Color(0xFFF6F0DF);
  static const Color parchment = Color(0xFFF7F1E1);
  static const Color warmParchment = Color(0xFFEDDFC1);
  static const Color ink = Color(0xFF1E1B16);
}
