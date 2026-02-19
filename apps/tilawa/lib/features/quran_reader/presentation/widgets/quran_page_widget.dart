import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilawa_core/constants/quran_constants.dart';

import '../../domain/entities/entities.dart';
import '../controllers/quran_page_audio_controller.dart';
// Actually I am rewriting the file.

class QuranPageWidget extends StatefulWidget {
  const QuranPageWidget({super.key, required this.page});

  final QuranPageEntity page;

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  // Controller scoped to the page widget.
  // In a real app with continuous playback across pages, this would be passed in or provided.
  // For this prototype/feature, scoping it here is fine, but we might want to keep playing when page turns?
  // User asked for "Mushaf-like layout", audio persistence wasn't strictly the new req, but nice to have.
  // Let's keep it here for now.
  final QuranPageAudioController _audioController = QuranPageAudioController();

  @override
  void dispose() {
    _audioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Group Ayahs by Surah
    final Map<int, List<PageAyahInfo>> ayahsBySurah = {};
    for (final PageAyahInfo ayah in widget.page.ayahs) {
      ayahsBySurah.putIfAbsent(ayah.surahNumber, () => []).add(ayah);
    }

    final List<MapEntry<int, List<PageAyahInfo>>> surahEntries = ayahsBySurah
        .entries
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: surahEntries.expand((entry) {
          final int surahNum = entry.key;
          final List<PageAyahInfo> ayahs = entry.value;
          final widgets = <Widget>[];

          // 2. Surah Header (except if it's strictly a continuation with no header needed?
          // Usually if a new Surah starts, we show header.
          // If the page starts with the middle of a Surah, we don't show header.)

          // Logic: If the first ayah of this group is Ayah 1, it's a new Surah (conceptually).
          // But sometimes (Page 1) it is Ayah 1.
          // Or if the map entry is logically a "block" of that Surah.
          // We only show header if it's the BEGINNING of the Surah.
          // How do we know? ayah.ayahNumber == 1.

          final bool isStartOfSurah = ayahs.any((a) => a.ayahNumber == 1);

          if (isStartOfSurah) {
            widgets.add(_buildSurahHeader(surahNum));
            widgets.add(const SizedBox(height: 16));

            // 3. Basmalah
            // Show for all Surahs except At-Tawbah (9) and Al-Fatihah (1) (as it's ayah 1 there).
            if (surahNum != 1 && surahNum != 9) {
              widgets.add(_buildBasmalah());
              widgets.add(const SizedBox(height: 16));
            }
          }

          // 4. Text Content
          widgets.add(
            SurahTextSection(ayahs: ayahs, audioController: _audioController),
          );

          // Spacing between surahs
          if (entry.key != surahEntries.last.key) {
            widgets.add(const SizedBox(height: 24));
          }

          return widgets;
        }).toList(),
      ),
    );
  }

  Widget _buildSurahHeader(int surahNumber) {
    final String surahName =
        QuranConstants.surahNames[surahNumber] ?? 'Surah $surahNumber';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EAD2), // Light beige/gold
        border: Border.all(color: Colors.brown.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'سورة $surahName',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade800,
          ),
        ),
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
  });

  final List<PageAyahInfo> ayahs;
  final QuranPageAudioController audioController;

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
    // Clear old recognizers on rebuild (e.g. if updated)
    // Note: In a real app, optimize to not rebuild recognizers if content is same.
    for (final TapGestureRecognizer r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    return ListenableBuilder(
      listenable: widget.audioController,
      builder: (context, child) {
        final int? playingId = widget.audioController.playingWordId;
        final spans = <InlineSpan>[];

        for (final PageAyahInfo ayah in widget.ayahs) {
          if (ayah.words != null) {
            for (final QuranWord word in ayah.words!) {
              final isPlaying = word.id == playingId;
              final recognizer = TapGestureRecognizer()
                ..onTap = () {
                  // Construct URL manually to fix API mismatch (off-by-one/skips)
                  // API returns e.g. ...014.mp3 for word 13, but correct audio is ...013.mp3
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

              spans.add(
                TextSpan(
                  text: word.textUthmani ?? word.text,
                  recognizer: recognizer,
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    height: 2.2,
                    color: isPlaying ? Colors.amber[900] : Colors.black,
                    backgroundColor: isPlaying
                        ? Colors.amber.withValues(alpha: 0.2)
                        : null,
                  ),
                ),
              );

              // Add space as a separate non-interactive span to preventing hit-test overlaps
              // especially after symbols like Waqf that might have wide bounding boxes.
              spans.add(
                TextSpan(
                  text: ' ',
                  style: GoogleFonts.amiri(fontSize: 24, height: 2.2),
                ),
              );
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
        }

        return RichText(
          text: TextSpan(children: spans),
          textAlign: TextAlign.justify,
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
