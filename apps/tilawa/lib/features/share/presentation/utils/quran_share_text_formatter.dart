import 'package:flutter/foundation.dart';
import 'package:term_glyph/term_glyph.dart' as glyph;
import 'package:tilawa/l10n/generated/app_localizations.dart';

enum QuranShareTextKind { screenshotPage, screenshotPassage, audio, reel }

String buildQuranShareText({
  required AppLocalizations l10n,
  required String surahName,
  required String arabicSurahName,
  required QuranShareTextKind kind,
  required int currentPage,
  required int fromAyah,
  required int toAyah,
  String? reciterName,
}) {
  final glyphs = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
      ? glyph.asciiGlyphs
      : glyph.unicodeGlyphs;

  final lines = <String>['${l10n.surahPrefix} $surahName'];

  if (surahName != arabicSurahName) {
    lines.add('${glyphs.bullet} $arabicSurahName');
  }

  switch (kind) {
    case QuranShareTextKind.screenshotPage:
      lines.add('${glyphs.bullet} ${l10n.page} $currentPage');
      lines.add('${glyphs.bullet} ${l10n.shareModeScreenshot}');
    case QuranShareTextKind.screenshotPassage:
      lines.add(
        '${glyphs.bullet} ${_buildAyahRange(l10n, glyphs, fromAyah, toAyah)}',
      );
      lines.add('${glyphs.bullet} ${l10n.shareModeScreenshot}');
    case QuranShareTextKind.audio:
      lines.add(
        '${glyphs.bullet} ${_buildAyahRange(l10n, glyphs, fromAyah, toAyah)}',
      );
      if (reciterName != null && reciterName.isNotEmpty) {
        lines.add('${glyphs.bullet} $reciterName');
      }
      lines.add('${glyphs.bullet} ${l10n.shareModeAudio}');
    case QuranShareTextKind.reel:
      lines.add(
        '${glyphs.bullet} ${_buildAyahRange(l10n, glyphs, fromAyah, toAyah)}',
      );
      if (reciterName != null && reciterName.isNotEmpty) {
        lines.add('${glyphs.bullet} $reciterName');
      }
      lines.add('${glyphs.bullet} ${l10n.shareModeReel}');
  }

  lines.add('${glyphs.bullet} ${l10n.sharedViaTilawa}');
  return lines.join('\n');
}

String _buildAyahRange(
  AppLocalizations l10n,
  glyph.GlyphSet glyphs,
  int fromAyah,
  int toAyah,
) {
  if (fromAyah == toAyah) {
    return '${l10n.ayah} $fromAyah';
  }

  return '${l10n.ayahs} $fromAyah ${glyphs.longRightArrow} $toAyah';
}
