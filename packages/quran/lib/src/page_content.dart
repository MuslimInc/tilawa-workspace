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
    this.onSurahSelected,
    this.onShowIndex,
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
  final ValueChanged<int>? onSurahSelected;
  final VoidCallback? onShowIndex;

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
                  WidgetSpan(
                    child: _SurahHeaderBanner(surahName: displaySurahName),
                  ),
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

          final double horizontalPadding = widget.pageNumber <= 2
              ? constraints.maxWidth * 0.15
              : constraints.maxWidth * 0.035;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                header,
                Expanded(
                  child: Center(
                    child: isLandscape
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: readerText,
                          )
                        : (widget.pageNumber <= 2
                              ? Center(child: readerText)
                              : readerText),
                  ),
                ),
                _PageFooter(
                  quarterNumber: quarterNumber,
                  pageNumber: widget.pageNumber,
                  hizbLabel: widget.hizbLabel ?? 'Hizb',
                  textColor: widget.textColor,
                  onSurahSelected: widget.onSurahSelected,
                  onShowIndex: widget.onShowIndex,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SurahHeaderBanner extends StatelessWidget {
  const _SurahHeaderBanner({required this.surahName});
  final String surahName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
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
              surahName,
              style: const TextStyle(
                fontFamily: 'assets/quran_fonts/QCF4_QBSML-Regular.woff',
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
    final double verseFontSize = MediaQuery.sizeOf(context).width * 0.034;

    return Row(
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
    );
  }
}

class _PageFooter extends StatelessWidget {
  const _PageFooter({
    required this.quarterNumber,
    required this.pageNumber,
    required this.hizbLabel,
    required this.textColor,
    required this.onSurahSelected,
    required this.onShowIndex,
  });

  final int? quarterNumber;
  final int pageNumber;
  final String hizbLabel;
  final Color textColor;
  final ValueChanged<int>? onSurahSelected;
  final VoidCallback? onShowIndex;

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

    final String hizbLabel = _getHizbLabel();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Surah Index Button (Integrated into content flow)
          _SurahIndexButton(onShowIndex: onShowIndex),

          // Pill info badge
          _QuranPageIndex(hizbLabel: hizbLabel, pageNumber: pageNumber),
        ],
      ),
    );
  }
}

class _QuranPageIndex extends StatelessWidget {
  const _QuranPageIndex({
    super.key,
    required this.hizbLabel,
    required this.pageNumber,
  });

  final String hizbLabel;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6D5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hizbLabel.isNotEmpty) ...[
            Text(
              hizbLabel,
              style: const TextStyle(
                color: Color(0xFF7A6855),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 14,
              color: const Color(0xFF7A6855).withValues(alpha: 0.3),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            '$pageNumber',
            style: const TextStyle(
              color: Color(0xFF7A6855),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahIndexButton extends StatelessWidget {
  const _SurahIndexButton({required this.onShowIndex});

  final VoidCallback? onShowIndex;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onShowIndex,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF8B6B4E),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        child: const Icon(
          Icons.menu_book_rounded,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}
