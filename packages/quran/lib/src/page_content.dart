import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../quran.dart';
import 'layout/quran_layout_strategy.dart';

class PageContent extends StatefulWidget {
  const PageContent({
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
  State<PageContent> createState() => _PageContentState();
}

class _PageContentState extends State<PageContent> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, int>> ranges = getPageData(widget.pageNumber);
    final pageFont = "QCF_P${widget.pageNumber.toString().padLeft(3, '0')}";

    // Use the strategy to calculate layout metrics
    final layoutStrategy = StandardQuranLayoutStrategy();
    final QuranLayoutMetrics metrics = layoutStrategy.calculateMetrics(context);

    // Alias for readability
    final double adaptiveFontSize = metrics.fontSize;
    final double adaptiveFontHeight = metrics.fontHeight;
    // The font files are Regular (w400). Custom weights like 550 often default to 400.
    // Using w700 (Standard Bold) to ensure a visibly thicker weight.
    const FontWeight fontWeight = FontWeight.w500;

    print('[PageContent] Page: ${widget.pageNumber}, Font: $pageFont');
    print(
      '[PageContent] Metrics: Font=$adaptiveFontSize, Height=$adaptiveFontHeight',
    );
    print('[PageContent] Ranges count: ${ranges.length}');

    final verseSpans = <InlineSpan>[];
    if (widget.pageNumber == 2 || widget.pageNumber == 1) {
      verseSpans.add(
        WidgetSpan(
          child: SizedBox(height: MediaQuery.sizeOf(context).height * .175),
        ),
      );
    }
    for (final r in ranges) {
      final int surah = r['surah']!;
      final int start = r['start']!;
      final int end = r['end']!;

      for (var v = start; v <= end; v++) {
        if (v == start && v == 1) {
          verseSpans.add(
            WidgetSpan(
              child: HeaderWidget(
                suraNumber: surah,
                fontSize: adaptiveFontSize,
              ),
            ),
          );
          if (widget.pageNumber != 1 && widget.pageNumber != 187) {
            if (surah != 97) {
              verseSpans.add(
                TextSpan(
                  text: ' ﱁ  ﱂﱃﱄ\n',
                  style: TextStyle(
                    fontFamily: 'QCF_P001',
                    package: 'quran',
                    fontSize: adaptiveFontSize,
                    fontWeight: fontWeight,
                    color: Colors.black,
                  ),
                ),
              );
            } else {
              verseSpans.add(
                TextSpan(
                  text: '齃𧻓𥳐龎\n',
                  style: TextStyle(
                    fontFamily: 'QCF_BSML',
                    package: 'quran',
                    fontSize: adaptiveFontSize * 0.75,
                    fontWeight: fontWeight,
                    color: Colors.black,
                  ),
                ),
              );
            }
          }
        }
        final spanRecognizer = LongPressGestureRecognizer();
        spanRecognizer.onLongPress = () => widget.onLongPress?.call(surah, v);
        spanRecognizer.onLongPressStart = (LongPressStartDetails d) =>
            widget.onLongPressDown?.call(surah, v, d);
        spanRecognizer.onLongPressUp = () =>
            widget.onLongPressUp?.call(surah, v);
        spanRecognizer.onLongPressEnd = (LongPressEndDetails d) =>
            widget.onLongPressCancel?.call(surah, v);

        final Color? verseBgColor = widget.verseBackgroundColor?.call(surah, v);

        // Debug first verse text
        if (v == start) {
          try {
            final String t = getVerseQCF(surah, v, verseEndSymbol: false);
            print('[PageContent] Verse $surah:$v text length: ${t.length}');
          } catch (e) {
            print('[PageContent] Error getting verse: $e');
          }
        }

        final String verseText = getVerseQCF(surah, v, verseEndSymbol: false);
        verseSpans.add(
          TextSpan(
            text: verseText,
            recognizer: spanRecognizer,
            style: TextStyle(
              fontFamily: pageFont,
              package: 'quran',
              fontSize: adaptiveFontSize,
              fontWeight: fontWeight,
              color: widget.textColor,
              height: adaptiveFontHeight,
              letterSpacing: metrics.letterSpacing,
              backgroundColor: verseBgColor,
            ),
            children: [
              /// Surah verse number span
              TextSpan(
                text: getVerseNumberQCF(surah, v),
                style: TextStyle(
                  fontFamily: pageFont,
                  package: 'quran',
                  fontSize: adaptiveFontSize,
                  fontWeight: FontWeight.normal,
                  color: Colors.brown,
                  height: 1.35,
                  backgroundColor: verseBgColor,
                ),
              ),
            ],
          ),
        );
      }
    }

    final content = Center(
      child: Text.rich(
        TextSpan(children: verseSpans),
        locale: const Locale('ar'),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: pageFont,
          package: 'quran',
          fontSize: adaptiveFontSize,
          fontWeight: fontWeight,
          color: widget.textColor,
          height: adaptiveFontHeight,
          letterSpacing: metrics.letterSpacing,
        ),
      ),
    );

    if (metrics.isScrollable ||
        widget.pageNumber == 1 ||
        widget.pageNumber == 2) {
      return Center(
        child: SingleChildScrollView(padding: metrics.padding, child: content),
      );
    }

    return Center(child: content);
  }
}
