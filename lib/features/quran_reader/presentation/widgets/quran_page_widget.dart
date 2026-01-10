import 'dart:core';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/extensions/number_extensions.dart';
import '../../domain/entities/entities.dart';
import '../bloc/quran_reader_bloc.dart';
import '../bloc/word_by_word_audio_bloc.dart';
import 'quran_page_footer.dart';
import 'quran_page_top_bar.dart';
import 'surah_header.dart';

class QuranPageWidget extends StatefulWidget {
  const QuranPageWidget({super.key, required this.page});

  final QuranPageEntity page;

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  @override
  Widget build(BuildContext context) {
    // Determine Page Font Family
    // Format: QCF_Pxxx (e.g., QCF_P001)
    final pageFontFamily =
        'QCF_P${widget.page.pageNumber.toString().padLeft(3, '0')}';

    return BlocBuilder<QuranReaderBloc, QuranReaderState>(
      buildWhen: (previous, current) {
        return previous.settings.fontSize != current.settings.fontSize ||
            // Rebuild if we get updated page content (e.g. loaded words)
            previous.pages[widget.page.pageNumber] !=
                current.pages[widget.page.pageNumber];
      },
      builder: (context, state) {
        final double currentFontSize = state.settings.fontSize;
        // Use the latest version of the page from the state, or fallback to the widget's initial version
        final QuranPageEntity page =
            state.pages[widget.page.pageNumber] ?? widget.page;

        // Data for Top and Bottom Bars
        final PageAyahInfo? firstAyah = page.ayahs.firstOrNull;
        final String surahNameEnglish = firstAyah?.surahNameEnglish ?? '';
        final int juzNumber = page.juz;
        final int hizbNumber = page.hizb;
        final int pageNumber = page.pageNumber;

        // Group Ayahs by Surah
        final Map<int, List<PageAyahInfo>> ayahsBySurah = {};
        for (final PageAyahInfo ayah in page.ayahs) {
          ayahsBySurah.putIfAbsent(ayah.surahNumber, () => []).add(ayah);
        }

        final List<MapEntry<int, List<PageAyahInfo>>> surahEntries =
            ayahsBySurah.entries.toList();

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
                        ? [const SizedBox(height: 50)] // Placeholder height
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

                            // Text Content
                            widgets.add(
                              SurahTextSection(
                                ayahs: ayahs,
                                fontFamily: pageFontFamily,
                                fontSize: currentFontSize,
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

              // 3. Bottom Footer
              QuranPageFooter(hizbNumber: hizbNumber, pageNumber: pageNumber),
            ],
          ),
        );
      },
    );
  }
}

class SurahTextSection extends StatefulWidget {
  const SurahTextSection({
    super.key,
    required this.ayahs,
    required this.fontFamily,
    required this.fontSize,
  });

  final List<PageAyahInfo> ayahs;
  final String fontFamily;
  final double fontSize;

  @override
  State<SurahTextSection> createState() => _SurahTextSectionState();
}

class _SurahTextSectionState extends State<SurahTextSection> {
  final List<TapGestureRecognizer> recognizers = [];

  @override
  void dispose() {
    for (final TapGestureRecognizer r in recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WordByWordAudioBloc, WordByWordAudioState>(
      builder: (context, state) {
        // Clear previous recognizers before building new ones to avoid leaks
        for (final TapGestureRecognizer r in recognizers) {
          r.dispose();
        }
        recognizers.clear();

        final int? playingId = state.playingWordId;
        final spans = <InlineSpan>[];

        for (final PageAyahInfo ayah in widget.ayahs) {
          if (ayah.words != null) {
            for (final QuranWord word in ayah.words!) {
              if (word.charTypeName == 'end') {
                continue;
              }

              final isPlaying = word.id == playingId;
              final recognizer = TapGestureRecognizer()
                ..onTap = () {
                  final String surahStr = ayah.surahNumber.toString().padLeft(
                    3,
                    '0',
                  );
                  final String ayahStr = ayah.ayahNumber.toString().padLeft(
                    3,
                    '0',
                  );
                  final String wordStr = word.position.toString().padLeft(
                    3,
                    '0',
                  );
                  final correctedUrl =
                      'wbw/${surahStr}_${ayahStr}_$wordStr.mp3';

                  context.read<WordByWordAudioBloc>().add(
                    WordByWordAudioEvent.playWord(correctedUrl, word.id),
                  );
                };
              recognizers.add(recognizer);

              // Use codeV1 if available for the specific page font glyph
              // Fallback to textUthmani if codeV1 is null
              final String textToRender =
                  word.codeV1 ?? word.textUthmani ?? word.text;

              // QCF Font Style
              spans.add(
                TextSpan(
                  text: textToRender,
                  recognizer: recognizer,
                  style: TextStyle(
                    fontFamily: widget.fontFamily,
                    fontSize: widget.fontSize, // Dynamic Size
                    height: 1.6,
                    color: isPlaying ? Colors.amber[900] : Colors.black,
                    backgroundColor: isPlaying
                        ? Colors.amber.withValues(alpha: 0.2)
                        : null,
                  ),
                ),
              );
              // Do NOT add extra spaces for QCF fonts generally as they are ligature fonts
            }
          } else {
            // Fallback
            spans.add(
              TextSpan(
                text: '${ayah.text} ',
                style: GoogleFonts.amiri(
                  fontSize: widget.fontSize,
                  height: 2.2,
                  color: Colors.black,
                ),
              ),
            );
          }

          // Ayah End Symbol
          final QuranWord? endWord = ayah.words?.firstWhere(
            (w) => w.charTypeName == 'end',
            orElse: () => const QuranWord(
              id: -1,
              position: -1,
              text: '',
              charTypeName: 'end',
            ),
          );

          if (endWord != null && endWord.codeV1 != null && endWord.id != -1) {
            spans.add(
              TextSpan(
                text: endWord.codeV1,
                style: TextStyle(
                  fontFamily: widget.fontFamily,
                  fontSize: widget.fontSize,
                  color: const Color(0xFFD4AF37), // Gold
                ),
              ),
            );
          } else {
            // Fallback
            spans.add(
              TextSpan(
                text: '\u06DD${ayah.ayahNumber.toArabicDigits()} ',
                style: GoogleFonts.amiri(
                  fontSize: widget.fontSize,
                  color: const Color(0xFFD4AF37),
                ),
              ),
            );
          }
        }

        return RichText(
          text: TextSpan(children: spans),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        );
      },
    );
  }
}
