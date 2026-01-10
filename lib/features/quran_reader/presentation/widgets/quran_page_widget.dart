import 'dart:core';

import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';
import 'quran_page_top_bar.dart';
import 'surah_header.dart';
import 'surah_text_section.dart';

/// A pure presentation widget for rendering a Quran page.
///
/// This widget receives page data with pre-computed font values.
/// It contains no business logic or state management.
class QuranPageWidget extends StatelessWidget {
  const QuranPageWidget({
    super.key,
    required this.page,
    required this.fontSize,
  });

  final QuranPageEntity page;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // Data for Top Bar
    final PageAyahInfo? firstAyah = page.ayahs.firstOrNull;
    final String surahNameEnglish = firstAyah?.surahNameEnglish ?? '';
    final int juzNumber = page.juz;

    // Group Ayahs by Surah
    final Map<int, List<PageAyahInfo>> ayahsBySurah = {};
    for (final PageAyahInfo ayah in page.ayahs) {
      ayahsBySurah.putIfAbsent(ayah.surahNumber, () => []).add(ayah);
    }

    final List<MapEntry<int, List<PageAyahInfo>>> surahEntries = ayahsBySurah
        .entries
        .toList();

    return ColoredBox(
      color: const Color(0xFFFFFBF3), // Cream background
      child: Column(
        children: [
          // 1. Top Bar
          QuranPageTopBar(
            surahNameEnglish: surahNameEnglish,
            juzNumber: juzNumber,
          ),

          // 2. Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: page.ayahs.isEmpty
                    ? [const SizedBox(height: 50)]
                    : surahEntries.expand((entry) {
                        final int surahNum = entry.key;
                        final List<PageAyahInfo> ayahs = entry.value;
                        final widgets = <Widget>[];

                        // Check if start of Surah
                        final bool isStartOfSurah = ayahs.any(
                          (a) => a.ayahNumber == 1,
                        );

                        if (isStartOfSurah) {
                          widgets.add(SurahHeader(surahNumber: surahNum));
                        }

                        // Text Content - fonts are pre-computed in data layer
                        widgets.add(
                          SurahTextSection(
                            words: ayahs
                                .map<List<QuranWord>>(
                                  (ayah) => ayah.words ?? [],
                                )
                                .expand((words) => words)
                                .toList(),
                            fontSize: fontSize,
                            surahNumber: surahNum,
                            ayahNumber: ayahs.first.ayahNumber,
                          ),
                        );

                        if (entry.key != surahEntries.last.key) {
                          widgets.add(const SizedBox(height: 24));
                        }

                        return widgets;
                      }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
