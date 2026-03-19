import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';

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
    final String surahName = context.l10n.localeName == 'ar'
        ? getSurahNameArabic(surahNumber)
        : getSurahNameEnglish(surahNumber);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EAD2), // Light beige/gold
        border: Border.all(color: Colors.brown.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${context.l10n.surahPrefix} $surahName',
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
  List<TapGestureRecognizer> _recognizers = [];

  // Cached text styles — avoid calling GoogleFonts on every build.
  static final TextStyle _baseStyle = GoogleFonts.amiri(
    fontSize: 24,
    height: 2.2,
    color: Colors.black,
  );
  static final TextStyle _spaceStyle = GoogleFonts.amiri(
    fontSize: 24,
    height: 2.2,
  );
  static final TextStyle _playingStyle = _baseStyle.copyWith(
    color: Colors.amber[900],
    backgroundColor: Colors.amber.withValues(alpha: 0.2),
  );

  @override
  void initState() {
    super.initState();
    _buildRecognizers();
  }

  @override
  void didUpdateWidget(covariant SurahTextSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.ayahs, widget.ayahs)) {
      _disposeRecognizers();
      _buildRecognizers();
    }
  }

  void _buildRecognizers() {
    final recognizers = <TapGestureRecognizer>[];
    for (final PageAyahInfo ayah in widget.ayahs) {
      if (ayah.words != null) {
        for (final QuranWord word in ayah.words!) {
          final recognizer = TapGestureRecognizer()
            ..onTap = () {
              final String surahStr = ayah.surahNumber.toString().padLeft(
                3,
                '0',
              );
              final String ayahStr = ayah.ayahNumber.toString().padLeft(3, '0');
              final String wordStr = word.position.toString().padLeft(3, '0');
              final correctedUrl = 'wbw/${surahStr}_${ayahStr}_$wordStr.mp3';

              widget.audioController.playWord(correctedUrl, word.id);
            };
          recognizers.add(recognizer);
        }
      }
    }
    _recognizers = recognizers;
  }

  void _disposeRecognizers() {
    for (final TapGestureRecognizer r in _recognizers) {
      r.dispose();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.audioController,
      builder: (context, child) {
        final int? playingId = widget.audioController.playingWordId;
        final spans = <InlineSpan>[];
        int recognizerIndex = 0;

        for (final PageAyahInfo ayah in widget.ayahs) {
          if (ayah.words != null) {
            for (final QuranWord word in ayah.words!) {
              final isPlaying = word.id == playingId;
              final recognizer = recognizerIndex < _recognizers.length
                  ? _recognizers[recognizerIndex]
                  : null;
              recognizerIndex++;

              spans.add(
                TextSpan(
                  text: word.textUthmani ?? word.text,
                  recognizer: recognizer,
                  style: isPlaying ? _playingStyle : _baseStyle,
                ),
              );

              // Non-interactive space span to prevent hit-test overlaps
              spans.add(TextSpan(text: ' ', style: _spaceStyle));
            }
          } else {
            // Fallback
            spans.add(TextSpan(text: '${ayah.text} ', style: _baseStyle));
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
