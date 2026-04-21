import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../quran_qcf.dart';
import 'helpers/app_logger.dart';

/// A horizontally swipeable Quran mushaf using internal QCF fonts.
///
/// Refactored to use a sliver-based architecture permitting `cacheExtent`.
/// This ensures adjacent pages are pre-rasterized on the GPU, eliminating
/// jank during the swipe gesture.
class QuranPageView extends StatefulWidget {
  const QuranPageView({
    super.key,
    required this.controller,
    this.onPageChanged,
    this.textColor = const Color(0xFF000000),
    this.pageBackgroundColor = const Color(0xFFFFF9F1),
    this.verseBackgroundColor,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
    this.juzLabel,
    this.hizbLabel,
    this.surahNameBuilder,
    this.onSurahSelected,
    this.onShowIndex,
    this.headerImageFilter,
    this.headerTextColor,
    this.headerFontSizeMultiplier =
        SurahHeaderBannerConstants.defaultFontSizeMultiplier,
    this.currentPageListenable,
    this.uiTextDirection = TextDirection.ltr,
    this.showOverlaysListenable,
    this.showShadows = true,
    this.onScrollStarted,
    this.onScrollEnded,
    this.cacheExtentListenable,
    this.preparedWindowListenable,
    this.isScrollingListenable,
  });

  /// Optional listenable to dynamically control the cache extent.
  /// Used to zero-out cache during jumps to eliminate 1st-frame jank.
  final ValueListenable<double>? cacheExtentListenable;
  final ValueListenable<PreparedQuranPageWindow?>? preparedWindowListenable;

  /// Scroll interaction callbacks for the parent to manage background tasks.
  final VoidCallback? onScrollStarted;
  final VoidCallback? onScrollEnded;

  /// Whether to render bold text shadows in [PageContent].
  final bool showShadows;

  final ValueListenable<bool>? showOverlaysListenable;
  final PageController controller;
  final ValueListenable<int>? currentPageListenable;
  final ValueChanged<int>? onPageChanged;
  final Color textColor;
  final Color pageBackgroundColor;
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
  final String? juzLabel;
  final String? hizbLabel;
  final String Function(int surahNumber)? surahNameBuilder;
  final ValueChanged<int>? onSurahSelected;
  final VoidCallback? onShowIndex;
  final ColorFilter? headerImageFilter;
  final Color? headerTextColor;
  final double headerFontSizeMultiplier;
  final TextDirection uiTextDirection;

  /// A listenable that is `true` while the user is actively swiping.
  ///
  /// When provided by the parent, [QuranPageView] uses it directly instead
  /// of managing its own. This allows the reader screen to centrally control
  /// the scroll state for both this view and the background warming service.
  final ValueListenable<bool>? isScrollingListenable;

  @override
  State<QuranPageView> createState() => _QuranPageViewState();
}

class _QuranPageViewState extends State<QuranPageView> {
  int _lastReportedPage = 0;

  @override
  void initState() {
    super.initState();
    _lastReportedPage = widget.controller.initialPage;
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      final double? offset = widget.controller.hasClients
          ? widget.controller.page
          : widget.controller.initialPage.toDouble();

      if (offset == null) return;

      final int currentPage = offset.round();
      if (currentPage != _lastReportedPage) {
        _lastReportedPage = currentPage;
        final int pageNumber = currentPage + 1;
        _debugLog(
          () =>
              '[PERF] Page changed to $pageNumber at ${DateTime.now().millisecondsSinceEpoch}ms',
        );
        widget.onPageChanged?.call(pageNumber);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final ValueListenable<bool>? listenable = widget.isScrollingListenable;
        if (listenable is ValueNotifier<bool>) {
          if (notification is ScrollStartNotification) {
            listenable.value = true;
          } else if (notification is ScrollUpdateNotification) {
            if (!listenable.value) listenable.value = true;
          } else if (notification is ScrollEndNotification ||
              notification is UserScrollNotification) {
            if (notification is ScrollEndNotification) {
              listenable.value = false;
            }
          }
        }
        if (notification is ScrollStartNotification) {
          widget.onScrollStarted?.call();
        } else if (notification is ScrollEndNotification) {
          widget.onScrollEnded?.call();
        }
        _handleScrollNotification(notification);
        return false;
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ColoredBox(
          color: widget.pageBackgroundColor,
          child: CustomScrollView(
            scrollDirection: Axis.horizontal,
            controller: widget.controller,
            physics: const PageScrollPhysics(),
            cacheExtent: widget.cacheExtentListenable?.value ?? 800,
            slivers: [
              SliverFillViewport(
                padEnds: false,
                delegate: SliverChildBuilderDelegate((context, index) {
                  final int pageNumber = index + 1;
                  return PageContent(
                    key: ValueKey<int>(pageNumber),
                    pageNumber: pageNumber,
                    preparedWindowListenable: widget.preparedWindowListenable,
                    textColor: widget.textColor,
                    verseBackgroundColor: widget.verseBackgroundColor,
                    onLongPress: widget.onLongPress,
                    onLongPressUp: widget.onLongPressUp,
                    onLongPressCancel: widget.onLongPressCancel,
                    onLongPressDown: widget.onLongPressDown,
                    juzLabel: widget.juzLabel,
                    hizbLabel: widget.hizbLabel,
                    surahNameBuilder: widget.surahNameBuilder,
                    onSurahSelected: widget.onSurahSelected,
                    onShowIndex: widget.onShowIndex,
                    headerImageFilter: widget.headerImageFilter,
                    headerTextColor: widget.headerTextColor,
                    headerFontSizeMultiplier: widget.headerFontSizeMultiplier,
                    pageBackgroundColor: widget.pageBackgroundColor,
                    uiTextDirection: widget.uiTextDirection,
                    currentPageListenable: widget.currentPageListenable,
                    showOverlaysListenable: widget.showOverlaysListenable,
                    isScrollingListenable: widget.isScrollingListenable,
                    showShadows: widget.showShadows,
                  );
                }, childCount: QuranConstants.totalPagesCount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _debugLog(String Function() messageBuilder) {
  if (!kReleaseMode) {
    logger.i(messageBuilder());
  }
}
