import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/quran_constants.dart';
import '../../domain/entities/entities.dart';
import '../controllers/quran_page_audio_controller.dart';

class QuranPageWidget extends StatefulWidget {
  const QuranPageWidget({super.key, required this.page});

  final QuranPageEntity page;

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  final QuranPageAudioController _audioController = QuranPageAudioController();

  @override
  void dispose() {
    _audioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine Page Font Family
    // Format: QCF_Pxxx (e.g., QCF_P001)
    final pageFontFamily =
        'QCF_P${widget.page.pageNumber.toString().padLeft(3, '0')}';

    // Group Ayahs by Surah
    final Map<int, List<PageAyahInfo>> ayahsBySurah = {};
    for (final PageAyahInfo ayah in widget.page.ayahs) {
      ayahsBySurah.putIfAbsent(ayah.surahNumber, () => []).add(ayah);
    }

    final List<MapEntry<int, List<PageAyahInfo>>> surahEntries = ayahsBySurah
        .entries
        .toList();

    // Data for Top and Bottom Bars
    final PageAyahInfo firstAyah = widget.page.ayahs.first;
    final String surahNameEnglish = firstAyah.surahNameEnglish;
    final int juzNumber = widget.page.juz;
    final int hizbNumber = widget.page.hizb;
    final int pageNumber = widget.page.pageNumber;

    return ColoredBox(
      color: const Color(0xFFFFFBF3), // Cream background
      child: Column(
        children: [
          // 1. Top Bar (Surah Name English | Part X)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            margin: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  surahNameEnglish,
                  style: GoogleFonts.amiri(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA1887F), // Brownish gray
                  ),
                ),
                Text(
                  'Part $juzNumber',
                  style: GoogleFonts.amiri(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA1887F),
                  ),
                ),
              ],
            ),
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
                children: surahEntries.expand((entry) {
                  final int surahNum = entry.key;
                  final List<PageAyahInfo> ayahs = entry.value;
                  final widgets = <Widget>[];

                  // Check if start of Surah
                  final bool isStartOfSurah = ayahs.any(
                    (a) => a.ayahNumber == 1,
                  );

                  if (isStartOfSurah) {
                    widgets.add(_buildSurahHeader(surahNum));
                    widgets.add(const SizedBox(height: 16));

                    // Basmalah: Show if not Surah 1 (Fatihah) and not Surah 9 (Tawbah).
                    // For Fatihah, Ayah 1 IS the Basmalah, so it renders as text.
                    // Actually for Page 1, the design shows Bismillah as calligraphy.
                    // The QCF font usually includes Bismillah in the glyphs if it's encoded as words.
                    // Fatihah Ayah 1 IS Bismillah. So it will render via SurahTextSection.
                    // Only for other surahs (e.g. Al-Baqarah start), we need to manually insert Bismillah
                    // IF it is not part of the words list. Usually it is NOT part of Ayah 1 for other surahs.
                    if (surahNum != 1 && surahNum != 9) {
                      widgets.add(_buildBasmalah());
                      widgets.add(const SizedBox(height: 16));
                    }
                  }

                  // Text Content
                  widgets.add(
                    SurahTextSection(
                      ayahs: ayahs,
                      audioController: _audioController,
                      fontFamily: pageFontFamily,
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

          // 3. Bottom Footer (Hizb | Page Number)
          Container(
            padding: const EdgeInsets.only(bottom: 24, top: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DAC0), // Darker beige for tag
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC7B299)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hizb $hizbNumber',
                      style: GoogleFonts.amiri(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                    Container(
                      height: 16,
                      width: 1,
                      color: Colors.brown.shade800,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    Text(
                      '$pageNumber',
                      style: GoogleFonts.amiri(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahHeader(int surahNumber) {
    final String surahName =
        QuranConstants.surahNames[surahNumber] ?? 'Surah $surahNumber';

    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6D5).withValues(alpha: 0.5),
        border: const Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFC7B299), width: 2),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Pattern (Placeholder for now)
          const Opacity(
            opacity: 0.1,
            child: Icon(Icons.pattern, size: 60, color: Colors.brown),
          ),

          // Surah Name (Image Asset)
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black87,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/surahNames/$surahNumber.png',
              // height: 90,
              width: double.infinity,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  'سُورَةُ $surahName',
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasmalah() {
    return Center(
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        style: GoogleFonts.amiri(fontSize: 24, color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SurahTextSection extends StatefulWidget {
  const SurahTextSection({
    super.key,
    required this.ayahs,
    required this.audioController,
    required this.fontFamily,
  });

  final List<PageAyahInfo> ayahs;
  final QuranPageAudioController audioController;
  final String fontFamily;

  @override
  State<SurahTextSection> createState() => _SurahTextSectionState();
}

class _SurahTextSectionState extends State<SurahTextSection> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final TapGestureRecognizer r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final TapGestureRecognizer r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    print('DEBUG: Page Font: ${widget.fontFamily}'); // Debug log

    return ListenableBuilder(
      listenable: widget.audioController,
      builder: (context, child) {
        final int? playingId = widget.audioController.playingWordId;
        final spans = <InlineSpan>[];

        for (final PageAyahInfo ayah in widget.ayahs) {
          if (ayah.words != null) {
            for (final QuranWord word in ayah.words!) {
              if (word.charTypeName == 'end') {
                continue;
              }

              // Debug first few words
              if (word.position < 3 && ayah.ayahNumber == 1) {
                print(
                  'DEBUG: Word ${word.id} (${word.text}): codeV1="${word.codeV1}", textUthmani="${word.textUthmani}"',
                );
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

                  widget.audioController.playWord(correctedUrl, word.id);
                };
              _recognizers.add(recognizer);

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
                    fontSize: 32, // Larger size for QCF fonts
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
                  fontSize: 24,
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
                  fontSize: 32,
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
                  fontSize: 24,
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

extension NumberConverter on int {
  String toArabicDigits() {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var input = toString();
    for (var i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }
}
