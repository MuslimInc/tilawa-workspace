import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../quran.dart';
import 'helpers/quran_text_paint.dart';

class QcfVerse extends StatefulWidget {
  const QcfVerse({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    this.fontSize,
    this.textColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0x00000000),
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
    this.sp = 1,
    this.h = 1,
  });
  final int surahNumber;
  final int verseNumber;
  final double? fontSize;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressUp;

  final VoidCallback? onLongPressCancel;
  final Function(LongPressDownDetails)? onLongPressDown;
  //sp (adding 1 to get the ratio of screen size for responsive font design)
  final double sp;

  //h (adding 1 to get the ratio of screen size for responsive font design)
  final double h;

  @override
  State<QcfVerse> createState() => _QcfVerseState();
}

class _QcfVerseState extends State<QcfVerse> {
  late final LongPressGestureRecognizer _recognizer;
  late int _pageNumber;
  late String _pageFont;

  @override
  void initState() {
    super.initState();
    _recognizer = LongPressGestureRecognizer();
    _computePageNumber();
  }

  @override
  void didUpdateWidget(covariant QcfVerse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber ||
        oldWidget.verseNumber != widget.verseNumber) {
      _computePageNumber();
    }
  }

  void _computePageNumber() {
    _pageNumber = getPageNumber(widget.surahNumber, widget.verseNumber);
    _pageFont = "QCF_P${_pageNumber.toString().padLeft(3, '0')}";
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update recognizer handlers
    _recognizer
      ..onLongPress = widget.onLongPress
      ..onLongPressDown = widget.onLongPressDown
      ..onLongPressUp = widget.onLongPressUp
      ..onLongPressCancel = widget.onLongPressCancel;

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      text: TextSpan(
        recognizer: _recognizer,
        text: getVerseQCF(
          widget.surahNumber,
          widget.verseNumber,
          verseEndSymbol: false,
        ),
        locale: const Locale('ar'),
        children: [
          TextSpan(
            text: getVerseNumberQCF(widget.surahNumber, widget.verseNumber),
            style: TextStyle(
              fontFamily: _pageFont,
              height: 1.35 / widget.h,
              color: widget.textColor,
            ),
          ),
        ],
        style: TextStyle(
          color: widget.textColor,
          height: 2.0 / widget.h,
          wordSpacing: 0,
          fontFamily: _pageFont,
          shadows: buildQuranBoldShadows(widget.textColor),
          backgroundColor: widget.backgroundColor,
        ),
      ),
    );
  }
}
