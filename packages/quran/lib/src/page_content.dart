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
    this.onLongPress,
    this.onLongPressUp,
    required this.onLongPressCancel,
    required this.onLongPressDown,
    this.juzLabel,
    this.hizbLabel,
    this.surahNameBuilder,
  });
  final int pageNumber;
  final Color textColor;
  final Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor;
  final void Function(int surahNumber, int verseNumber)? onLongPress;
  final void Function(int surahNumber, int verseNumber)? onLongPressUp;
  final void Function(int surahNumber, int verseNumber)? onLongPressCancel;
  final String? juzLabel;
  final String? hizbLabel;
  final String Function(int surahNumber)? surahNameBuilder;

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
    final double screenWidth = MediaQuery.sizeOf(context).width;

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final double verseFontSize = screenWidth * 0.055;
    final double ayahNumberFontSize = screenWidth * 0.055;
    final double bismillahFontSize = isLandscape
        ? screenWidth * 0.045
        : screenWidth * 0.055;

    final List<Map<String, int>> ranges = getPageData(widget.pageNumber);
    final Map<String, int> firstVerse = ranges.first;
    final int surahNumber = firstVerse['surah']!;
    final int juzNumber = QuranServiceLocator.quranDataService.getJuzNumber(
      surahNumber,
      firstVerse['start']!,
    );
    final int? quarterNumber = widget.pageNumber == 1 || widget.pageNumber == 2
        ? null
        : QuranServiceLocator.quranDataService.getQuarterNumber(
            surahNumber,
            firstVerse['start']!,
          );

    final String displaySurahName =
        widget.surahNameBuilder?.call(surahNumber) ??
        QuranServiceLocator.surahService
            .getName(surahNumber)
            .replaceAll('Al ', 'Al-');

    final pageFont = "QCF_P${widget.pageNumber.toString().padLeft(3, '0')}";

    // Use the strategy to calculate layout metrics
    final layoutStrategy = StandardQuranLayoutStrategy();
    // final QuranLayoutMetrics metrics = layoutStrategy.calculateMetrics(context);

    // Alias for readability
    // final double adaptiveFontSize = metrics.fontSize;
    // final double adaptiveFontHeight = metrics.fontHeight;
    const FontWeight fontWeight = FontWeight.w500;

    final verseSpans = <InlineSpan>[];
    var isFirstVerseOfPage = true;
    for (final r in ranges) {
      final int surah = r['surah']!;
      final int start = r['start']!;
      final int end = r['end']!;

      for (var v = start; v <= end; v++) {
        if (v == start && v == 1) {
          verseSpans.add(WidgetSpan(child: HeaderWidget(suraNumber: surah)));
          verseSpans.add(const TextSpan(text: '\n\n'));
          if (surah != 1 && surah != 9) {
            verseSpans.add(
              TextSpan(
                text: '\ufad8\ufad7\ufad6\ufad5\n',
                style: TextStyle(
                  fontFamily: 'QCF_BSML',
                  package: 'quran',
                  fontSize: bismillahFontSize,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
            );
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
        final String verseText = _spaceQcfGlyphs(
          getVerseQCF(surah, v, verseEndSymbol: false),
          isFirstVerseOnPage: isFirstVerseOfPage,
        );
        isFirstVerseOfPage = false;

        verseSpans.add(
          TextSpan(
            text: verseText,
            recognizer: spanRecognizer,
            style: TextStyle(
              fontFamily: pageFont,
              package: 'quran',

              /// Dynamic font size based on screen size
              fontSize: verseFontSize,
              color: widget.textColor,
              height: 2.45,
              // backgroundColor: verseBgColor,
            ),
            children: [
              TextSpan(
                text: getVerseNumberQCF(surah, v),
                style: TextStyle(
                  fontFamily: pageFont,
                  package: 'quran',

                  /// Ayah number font size
                  fontSize: ayahNumberFontSize,
                  fontWeight: FontWeight.normal,
                  // color: Colors.green,
                  height: 2.25,
                  backgroundColor: verseBgColor,
                ),
              ),
            ],
          ),
        );
      }
    }

    final Widget readerText = RichText(
      text: TextSpan(children: verseSpans),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      strutStyle: StrutStyle(fontSize: verseFontSize),
    );

    final header = _PageHeader(
      surahName: displaySurahName,
      juzNumber: juzNumber,
      juzLabel: widget.juzLabel ?? 'Part',
      textColor: widget.textColor,
    );
    final footer = _PageFooter(
      quarterNumber: quarterNumber,
      pageNumber: widget.pageNumber,
      hizbLabel: widget.hizbLabel ?? 'Hizb',
      textColor: widget.textColor,
    );

    final double horizontalPadding = screenWidth * 0.020;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        // vertical: MediaQuery.sizeOf(context).height * 0.030,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            child: isLandscape
                ? SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 45.0, bottom: 45.0),
                    child: readerText,
                  )
                : readerText,
          ),
          Positioned(top: 8, left: 0, right: 0, child: header),
          Positioned(bottom: 12, left: 0, right: 0, child: footer),
        ],
      ),
    );
  }

  /// Inserts a space between each consecutive QCF glyph on the same line.
  /// This is needed because Flutter's RTL text rendering ignores letterSpacing
  /// for Arabic clusters — explicit spaces are the only reliable way to
  /// create visual gaps between QCF word-glyphs.
  String _spaceQcfGlyphs(String qcfText, {bool isFirstVerseOnPage = false}) {
    if (!isFirstVerseOnPage || qcfText.isEmpty) return qcfText;

    if (qcfText.length >= 2 && !qcfText.contains('\u2009')) {
      if (qcfText[1] == ' ') {
        return '${qcfText[0]}\u2009${qcfText.substring(2)}';
      }
      return '${qcfText[0]}\u2009${qcfText.substring(1)}';
    }

    return qcfText;
  }

  String _addWhiteSpace(bool isFirstVerseOnPage, String verseText) {
    if (isFirstVerseOnPage && verseText.isNotEmpty) {
      if (verseText.length > 1 &&
          verseText[1] != ' ' &&
          verseText[1] != '\u2009') {
        verseText = '${verseText[0]}\u2009${verseText.substring(1)}';
      } else if (verseText.length == 1 &&
          verseText != ' ' &&
          verseText != '\u2009') {
        verseText = '$verseText\u2009';
      }
      isFirstVerseOnPage = false;
    }
    return verseText;
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.surahName,
    required this.juzNumber,
    required this.textColor,
    required this.juzLabel,
  });

  final String surahName;
  final int juzNumber;
  final Color textColor;
  final String juzLabel;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFA68B67);
    final double verseFontSize = MediaQuery.sizeOf(context).width * 0.020;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              surahName,
              style: TextStyle(
                color: primaryColor,
                fontSize: verseFontSize,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              '$juzLabel $juzNumber',
              style: TextStyle(
                color: primaryColor,
                fontSize: verseFontSize,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageFooter extends StatelessWidget {
  const _PageFooter({
    required this.quarterNumber,
    required this.pageNumber,
    required this.hizbLabel,
    required this.textColor,
  });

  final int? quarterNumber;
  final int pageNumber;
  final String hizbLabel;
  final Color textColor;

  String _getHizbLabel() {
    if (quarterNumber == null) return '';
    final int hizbIndex = (quarterNumber! - 1) ~/ 4 + 1;
    final int quarterInHizb = (quarterNumber! - 1) % 4;

    final String prefix;
    switch (quarterInHizb) {
      case 0:
        prefix = '';
      case 1:
        prefix = '1/4 ';
      case 2:
        prefix = '1/2 ';
      case 3:
        prefix = '3/4 ';
      default:
        prefix = '';
    }

    return '$prefix$hizbLabel $hizbIndex';
  }

  @override
  Widget build(BuildContext context) {
    if (pageNumber == 1 || pageNumber == 2) return const SizedBox.shrink();

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final double screenWidth = MediaQuery.sizeOf(context).width;

    // Use responsive font sizes rather than fixed .sp which can act weirdly in landscape
    final double fontSize = screenWidth * (isLandscape ? 0.015 : 0.025);
    final verticalPadding = isLandscape ? 4.0 : 6.0;
    final bottomPadding = isLandscape ? 12.0 : 22.0;

    const primaryColor = Color(0xFFA68B67);
    const bgColor = Color(0xFFF4EFE6);
    const borderColor = Color(0xFFDED3C4);
    final String hizbLabel = _getHizbLabel();

    return Align(
      alignment: pageNumber.isOdd
          ? Alignment.bottomRight
          : Alignment.bottomLeft,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hizbLabel.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  hizbLabel,
                  style: TextStyle(
                    color: primaryColor.withValues(alpha: 0.9),
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(width: 0.8, height: fontSize * 1.5, color: borderColor),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                '$pageNumber',
                style: TextStyle(
                  color: primaryColor.withValues(alpha: 0.9),
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
