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
    final double screenWidth = MediaQuery.sizeOf(context).width;

    final double verseFontSize = screenWidth * 0.055;
    final double ayahNumberFontSize = screenWidth * 0.060;
    final double bismillahFontSize = screenWidth * 0.060;

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

    final String englishSurahName = QuranServiceLocator.surahService
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
    var isFirstVerseOnPage = true;
    for (final r in ranges) {
      final int surah = r['surah']!;
      final int start = r['start']!;
      final int end = r['end']!;

      for (var v = start; v <= end; v++) {
        if (v == start && v == 1) {
          verseSpans.add(WidgetSpan(child: HeaderWidget(suraNumber: surah)));
          if (widget.pageNumber != 1 && widget.pageNumber != 187) {
            if (surah != 97) {
              verseSpans.add(
                TextSpan(
                  text: ' ﱁ  ﱂﱃﱄ\n',
                  style: TextStyle(
                    fontFamily: 'QCF_P001',
                    package: 'quran',
                    fontSize: bismillahFontSize,
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
                    fontSize: bismillahFontSize,
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

        String verseText = getVerseQCF(surah, v, verseEndSymbol: false);
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

        verseSpans.add(
          TextSpan(
            text: verseText,
            recognizer: spanRecognizer,
            style: TextStyle(
              fontFamily: pageFont,
              package: 'quran',

              /// Dynamic font size based on screen size
              fontSize: verseFontSize,
              fontWeight: fontWeight,
              color: widget.textColor,
              height: 2,
              letterSpacing: 2,
              backgroundColor: verseBgColor,
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

    final Widget readerText = Center(
      child: Text.rich(
        TextSpan(children: [...verseSpans]),
        locale: const Locale('ar'),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: pageFont,
          package: 'quran',
          fontSize: verseFontSize,
          fontWeight: fontWeight,
          color: widget.textColor,
          height: 2,
          letterSpacing: 2,
        ),
      ),
    );

    final header = _PageHeader(
      surahName: englishSurahName,
      juzNumber: juzNumber,
      textColor: widget.textColor,
    );
    final footer = _PageFooter(
      quarterNumber: quarterNumber,
      pageNumber: widget.pageNumber,
      textColor: widget.textColor,
    );

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final double horizontalPadding = screenWidth * 0.040;

    if (widget.pageNumber == 1 || widget.pageNumber == 2 || isLandscape) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [header, readerText, footer],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(child: readerText),
          footer,
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.surahName,
    required this.juzNumber,
    required this.textColor,
  });

  final String surahName;
  final int juzNumber;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    // Muted gold/brown color from screenshot
    const primaryColor = Color(0xFFA68B67);
    final double verseFontSize = MediaQuery.sizeOf(context).width * 0.030;

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
              'Part $juzNumber',
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
    required this.textColor,
  });

  final int? quarterNumber;
  final int pageNumber;
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

    return '${prefix}Hizb $hizbIndex';
  }

  @override
  Widget build(BuildContext context) {
    if (pageNumber == 1 || pageNumber == 2) return const SizedBox.shrink();

    final double hizbFontSize = MediaQuery.sizeOf(context).width * 0.030;
    final double pageNumberFontSize = MediaQuery.sizeOf(context).width * 0.030;

    const primaryColor = Color(0xFFA68B67);
    const bgColor = Color(0xFFF4EFE6);
    const borderColor = Color(0xFFDED3C4);
    final String hizbLabel = _getHizbLabel();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0, top: 4.0),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          height: 28,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hizbLabel.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    hizbLabel,
                    style: TextStyle(
                      color: primaryColor.withValues(alpha: 0.9),
                      fontSize: hizbFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  width: 0.8,
                  height: double.infinity,
                  color: borderColor,
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  '$pageNumber',
                  style: TextStyle(
                    color: primaryColor.withValues(alpha: 0.9),
                    fontSize: pageNumberFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
