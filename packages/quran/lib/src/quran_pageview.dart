import 'package:flutter/material.dart';

import '../quran.dart';
import 'constants/quran_constants.dart';
import 'page_content.dart';

/// A horizontally swipeable Quran mushaf using internal QCF fonts.
///
/// - Uses `pageData` to determine surah/verse ranges for each page.
/// - Renders each verse with `QcfVerse`, which applies the correct per-page font.
/// - Supports RTL page order via `reverse: true` and `Directionality.rtl`.
class PageviewQuran extends StatefulWidget {
  const PageviewQuran({
    super.key,
    this.initialPageNumber = 1,
    this.controller,
    this.onPageChanged,
    this.textColor = const Color(0xFF000000),
    this.pageBackgroundColor = const Color(0xFFFFFFFF),
    this.verseBackgroundColor,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
  }) : assert(
         initialPageNumber >= 1 &&
             initialPageNumber <= QuranConstants.totalPagesCount,
       );

  /// 1-based initial page number (1..604)
  final int initialPageNumber;

  /// Optional external controller. If not provided, an internal one is created.
  final PageController? controller;

  /// Optional callback when page changes. Provides 1-based page number.
  final ValueChanged<int>? onPageChanged;

  /// Verse text color.
  final Color textColor;

  /// Background color for the whole page container.
  final Color pageBackgroundColor;

  /// Optional callback to get background color for individual verses.
  /// Returns a Color for the verse, or null for no background color.
  /// Useful for highlighting selected verses.
  final Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor;

  /// Long-press callbacks that include the pressed verse info.
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
  State<PageviewQuran> createState() => _PageviewQuranState();
}

class _PageviewQuranState extends State<PageviewQuran> {
  PageController? _internalController;

  PageController get _controller => widget.controller ?? _internalController!;

  bool get _ownsController => widget.controller == null;

  @override
  void initState() {
    super.initState();
    if (_ownsController) {
      _internalController = PageController(
        initialPage: widget.initialPageNumber - 1,
      );
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _internalController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: widget.pageBackgroundColor,
        child: PageView.builder(
          controller: _controller,
          itemCount: QuranConstants.totalPagesCount,
          onPageChanged: (index) =>
              widget.onPageChanged?.call(index + 1), // 1-based
          itemBuilder: (context, index) {
            final int pageNumber = index + 1; // 1-based page
            return PageContent(
              pageNumber: pageNumber,
              textColor: widget.textColor,
              verseBackgroundColor: widget.verseBackgroundColor,
              onLongPress: widget.onLongPress,
              onLongPressUp: widget.onLongPressUp,
              onLongPressCancel: widget.onLongPressCancel,
              onLongPressDown: widget.onLongPressDown,
            );
          },
        ),
      ),
    );
  }
}
