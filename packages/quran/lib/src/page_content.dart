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
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;

          // Use the strategy to calculate layout metrics based on actual available space
          final layoutStrategy = StandardQuranLayoutStrategy();
          final QuranLayoutMetrics metrics = layoutStrategy.calculateMetrics(
            context,
            constraints,
          );

          final double verseFontSize = metrics.fontSize;
          final double fontHeight = metrics.fontHeight;
          final double ayahNumberFontSize = metrics.fontSize;
          final double bismillahFontSize = isLandscape
              ? constraints.maxWidth * 0.045
              : constraints.maxWidth * 0.055;

          final List<Map<String, int>> ranges = getPageData(widget.pageNumber);
          final Map<String, int> firstVerse = ranges.first;
          final int surahNumber = firstVerse['surah']!;
          final int juzNumber = QuranServiceLocator.quranDataService
              .getJuzNumber(surahNumber, firstVerse['start']!);
          final int? quarterNumber =
              widget.pageNumber == 1 || widget.pageNumber == 2
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

          final pageFont =
              "QCF_P${widget.pageNumber.toString().padLeft(3, '0')}";

          final verseSpans = <InlineSpan>[];
          for (final r in ranges) {
            final int surah = r['surah']!;
            final int start = r['start']!;
            final int end = r['end']!;

            for (var v = start; v <= end; v++) {
              if (v == start && v == 1) {
                verseSpans.add(
                  WidgetSpan(child: _SurahHeaderBanner(suraNumber: surah)),
                );
                verseSpans.add(const TextSpan(text: '\n'));
                if (surah != 1 && surah != 9) {
                  final String bismillahText = getVerseQCF(
                    1,
                    1,
                    verseEndSymbol: false,
                  );

                  verseSpans.add(
                    WidgetSpan(
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Text(
                          bismillahText,
                          style: TextStyle(
                            fontFamily: 'QCF_P001',
                            fontSize: bismillahFontSize * 1.1,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  );
                  verseSpans.add(const TextSpan(text: '\n'));
                }
              }
              final spanRecognizer = LongPressGestureRecognizer();
              spanRecognizer.onLongPress = () =>
                  widget.onLongPress?.call(surah, v);
              spanRecognizer.onLongPressStart = (LongPressStartDetails d) =>
                  widget.onLongPressDown?.call(surah, v, d);
              spanRecognizer.onLongPressUp = () =>
                  widget.onLongPressUp?.call(surah, v);
              spanRecognizer.onLongPressEnd = (LongPressEndDetails d) =>
                  widget.onLongPressCancel?.call(surah, v);

              final Color? verseBgColor = widget.verseBackgroundColor?.call(
                surah,
                v,
              );
              final String verseText = getVerseQCF(
                surah,

                /// Make is false if the page is 1 or 2
                addSpace: widget.pageNumber != 1 && widget.pageNumber != 2,
                v,
                verseEndSymbol: false,
              );

              verseSpans.add(
                TextSpan(
                  text: '$verseText ',
                  recognizer: spanRecognizer,
                  style: TextStyle(
                    fontFamily: pageFont,
                    fontSize: verseFontSize,
                    color: widget.textColor,
                    height: fontHeight,
                    letterSpacing: metrics.letterSpacing,
                  ),
                  children: [
                    TextSpan(
                      text: '${getVerseNumberQCF(surah, v)} ',
                      style: TextStyle(
                        fontFamily: pageFont,
                        fontSize: ayahNumberFontSize,
                        fontWeight: FontWeight.normal,
                        height: fontHeight,
                        letterSpacing: metrics.letterSpacing,
                        backgroundColor: verseBgColor,
                      ),
                    ),
                  ],
                ),
              );
            }
          }

          // Force full justification for the last line of the Mushaf page.
          // Flutter's TextAlign.justify skips the last line; appending a wide
          // zero-height widget forces the text onto a 'non-terminal' line.
          verseSpans.add(
            const WidgetSpan(
              child: SizedBox(width: double.infinity, height: 0),
            ),
          );

          final Widget readerText = RichText(
            text: TextSpan(children: verseSpans),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            strutStyle: StrutStyle(
              fontSize: verseFontSize,
              height: fontHeight,
              forceStrutHeight: true,
            ),
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

          final double horizontalPadding = widget.pageNumber <= 2
              ? constraints.maxWidth * 0.15
              : constraints.maxWidth * 0.035;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 45,
                  bottom: 55,
                  left: 0,
                  right: 0,
                  child: isLandscape
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.only(
                            top: 45.0,
                            bottom: 45.0,
                          ),
                          child: readerText,
                        )
                      : (widget.pageNumber <= 2
                            ? Center(child: readerText)
                            : readerText),
                ),
                Positioned(top: 8, left: 0, right: 0, child: header),
                Positioned(bottom: 12, left: 0, right: 0, child: footer),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SurahHeaderBanner extends StatelessWidget {
  const _SurahHeaderBanner({required this.suraNumber});
  final int suraNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Image(
            image: AssetImage('assets/mainframe.png', package: 'quran'),
            width: double.infinity,
            fit: BoxFit.contain,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              '$suraNumber',
              style: const TextStyle(
                fontFamily: 'arsura',
                package: 'quran',
                color: Colors.black,
                fontSize: 24,
              ),
            ),
          ),
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
    required this.juzLabel,
  });

  final String surahName;
  final int juzNumber;
  final Color textColor;
  final String juzLabel;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF7A6855);
    final double verseFontSize = MediaQuery.sizeOf(context).width * 0.040;

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
                fontWeight: FontWeight.bold,
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
    if (quarterNumber == null) {
      return '';
    }
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
    if (pageNumber == 1 || pageNumber == 2) {
      return const SizedBox.shrink();
    }

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final double screenWidth = MediaQuery.sizeOf(context).width;

    // Use responsive font sizes rather than fixed .sp which can act weirdly in landscape
    final double fontSize = screenWidth * (isLandscape ? 0.020 : 0.035);
    final verticalPadding = isLandscape ? 4.0 : 6.0;

    const primaryColor = Color(0xFF7A6855);
    const bgColor = Color(0xFFE8E0D1);
    const borderColor = Color(0xFFDED3C4);
    final String hizbLabel = _getHizbLabel();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
