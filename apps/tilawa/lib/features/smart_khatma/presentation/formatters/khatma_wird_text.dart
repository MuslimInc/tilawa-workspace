import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

import '../../domain/khatma_plan_boundaries.dart';

const int _openingVersePreviewMaxLength = 80;

String formatKhatmaSurahAyah(
  AppLocalizations l10n,
  Locale locale,
  int surah,
  int ayah,
) {
  final bool arabic = locale.languageCode == 'ar';
  final String surahName = arabic
      ? getSurahNameArabic(surah)
      : getSurahNameEnglish(surah);
  return l10n.khatmaSurahAyahLabel(surahName, ayah);
}

String? openingVersePreview(int page) {
  final ({int surah, int ayah})? verse = KhatmaPlanBoundaries.firstVerseOnPage(
    page,
  );
  if (verse == null) return null;

  final String text = getVerse(verse.surah, verse.ayah, verseEndSymbol: false);
  if (text.length <= _openingVersePreviewMaxLength) {
    return text;
  }
  return '${text.substring(0, _openingVersePreviewMaxLength).trim()}…';
}

int? juzForPage(int page) => KhatmaPlanBoundaries.juzForPage(page);
