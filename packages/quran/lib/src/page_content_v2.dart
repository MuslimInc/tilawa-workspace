import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../quran.dart';
import 'layout/quran_layout_strategy.dart';

class PageContentV2 extends StatefulWidget {
  const PageContentV2({
    super.key,
    required this.pageNumber,
    required this.textColor,
    this.verseBackgroundColor,
    required this.onLongPress,
    required this.onLongPressUp,
    required this.onLongPressCancel,
    required this.onLongPressDown,
  });

  final int pageNumber;
  final Color textColor;
  final Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor;
  final void Function(int surahNumber, int verseNumber)? onLongPress;
  final void Function(int surahNumber, int verseNumber)? onLongPressUp;
  final void Function(int surahNumber, int verseNumber)? onLongPressCancel;

  final void Function(
    int surahNumber,
    int verseNumber,
    LongPressStartDetails details,
  )?
  onLongPressDown;

  @override
  State<PageContentV2> createState() => _PageContentV2State();
}

class _PageContentV2State extends State<PageContentV2> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    const pageFont = 'UthmanicHafsV22';

    // 1. Calculate Layout Metrics
    final layoutStrategy = StandardQuranLayoutStrategy();
    final QuranLayoutMetrics metrics = layoutStrategy.calculateMetrics(context);

    // 2. Build single TextSpan tree
    final List<InlineSpan> textSpans = [];

    // Optional top padding for first pages
    if (widget.pageNumber == 1 || widget.pageNumber == 2) {
      textSpans.add(
        WidgetSpan(
          child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.1),
        ),
      );
      textSpans.add(const TextSpan(text: '\n'));
    }

    final List<Map<String, int>> ranges = getPageData(widget.pageNumber);

    for (final range in ranges) {
      final int surah = range['surah']!;
      final int start = range['start']!;
      final int end = range['end']!;

      // Header
      if (start == 1) {
        textSpans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: HeaderWidget(suraNumber: surah),
            ),
          ),
        );
        textSpans.add(const TextSpan(text: '\n'));

        // Basmalah (centered, wrapped in WidgetSpan to avoid justification stretch)
        if (surah != 1 && surah != 9) {
          textSpans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: pageFont,
                      package: 'quran',
                      fontSize: metrics.fontSize * 1.2,
                      color: widget.textColor,
                    ),
                  ),
                ),
              ),
            ),
          );
          textSpans.add(const TextSpan(text: '\n'));
        }
      }

      // Verses
      for (var v = start; v <= end; v++) {
        final String verseText = getVerse(surah, v);
        final String verseEnd = _getVerseEndSymbol(v);

        final spanRecognizer = LongPressGestureRecognizer();
        spanRecognizer.onLongPress = () => widget.onLongPress?.call(surah, v);
        spanRecognizer.onLongPressStart = (LongPressStartDetails d) =>
            widget.onLongPressDown?.call(surah, v, d);
        spanRecognizer.onLongPressUp = () =>
            widget.onLongPressUp?.call(surah, v);
        spanRecognizer.onLongPressEnd = (LongPressEndDetails d) =>
            widget.onLongPressCancel?.call(surah, v);

        final Color? verseBgColor = widget.verseBackgroundColor?.call(surah, v);

        textSpans.add(
          TextSpan(
            text: '$verseText$verseEnd',
            recognizer: spanRecognizer,
            style: TextStyle(
              fontFamily: pageFont,
              package: 'quran',
              fontSize: metrics.fontSize,
              color: widget.textColor,
              backgroundColor: verseBgColor,
              height: 1.7, // Fixed tight height aesthetic
            ),
            children: const [TextSpan(text: ' ')],
          ),
        );
      }
    }

    // Wrap in Text.rich with Justify to match "fill full width" request
    // We use Text.rich instead of SelectableText.rich to strictly match page_content.dart's rendering widget type
    final content = Text.rich(
      TextSpan(children: textSpans),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );

    if (metrics.isScrollable) {
      return SingleChildScrollView(
        padding: metrics.padding.add(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: content,
      );
    }

    // Ensure full width in portrait mode even when centered
    return Center(
      child: SingleChildScrollView(
        padding: metrics.padding.add(
          const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
        ),
        child: SizedBox(width: double.infinity, child: content),
      ),
    );
  }

  String _getVerseEndSymbol(int verseNumber) {
    const arabicDigits = <String, String>{
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };

    final List<String> digits = verseNumber.toString().split('');
    final String arabicNumber = digits.map((d) => arabicDigits[d]).join();

    // Uthmanic Hafs v22 specific:
    // Analysis of usage in docx shows only Arabic-Indic digits are used.
    // The font likely includes the frame/circle glyph within the digit glyphs themselves,
    // or through OpenType features activated by the digits.
    // We remove \u06dd to avoid "double circle/markers".
    return arabicNumber;
  }
}
