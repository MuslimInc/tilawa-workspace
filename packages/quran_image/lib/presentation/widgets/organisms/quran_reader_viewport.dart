import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/quran_image_page.dart';

class QuranReaderViewport extends StatelessWidget {
  const QuranReaderViewport({
    super.key,
    required this.pageController,
    required this.onToggleNavigation,
    required this.onShowNavigation,
    required this.onPageChanged,
    this.firstPage = 1,
    this.pageCount = PageState.quranPageCount,
    this.headerImageFilter,
  });

  final PageController pageController;
  final VoidCallback onToggleNavigation;
  final VoidCallback onShowNavigation;
  final ValueChanged<int> onPageChanged;

  /// First absolute Mushaf page in the allowed range.
  final int firstPage;

  /// Number of pages in the allowed range.
  final int pageCount;

  final ColorFilter? headerImageFilter;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('QuranReaderViewport');
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kDebugMode) {
          PerfLogger.log(
            widgetName: 'QuranImageReader Layout Builder',
            message:
                'LayoutBuilder constraints=$constraints '
                'maxWidth=${constraints.maxWidth} '
                'maxHeight=${constraints.maxHeight}',
          );
        }
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        return GestureDetector(
          onTap: onToggleNavigation,
          onVerticalDragStart: isLandscape ? null : (_) => onShowNavigation(),
          child: PageView.builder(
            controller: pageController,
            itemCount: pageCount,
            allowImplicitScrolling: false,
            physics: const PageScrollPhysics(),
            onPageChanged: (index) => onPageChanged(
              PageState.indexToPage(index, firstPage: firstPage),
            ),
            itemBuilder: (_, index) {
              final pageNumber = PageState.indexToPage(
                index,
                firstPage: firstPage,
              );
              return QuranImagePage(
                key: ValueKey<int>(pageNumber),
                pageNumber: pageNumber,
                headerImageFilter: headerImageFilter,
              );
            },
          ),
        );
      },
    );
  }
}
