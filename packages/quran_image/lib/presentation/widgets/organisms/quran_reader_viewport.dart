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
    this.headerImageFilter,
  });

  final PageController pageController;
  final VoidCallback onToggleNavigation;
  final VoidCallback onShowNavigation;
  final ValueChanged<int> onPageChanged;
  final ColorFilter? headerImageFilter;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('QuranReaderViewport');
    return LayoutBuilder(
      builder: (context, constraints) {
        PerfLogger.log(
          widgetName: 'QuranImageReader Layout Builder',
          message:
              'LayoutBuilder constraints=$constraints '
              'maxWidth=${constraints.maxWidth} '
              'maxHeight=${constraints.maxHeight}',
        );
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        return GestureDetector(
          onTap: onToggleNavigation,
          onVerticalDragStart: isLandscape ? null : (_) => onShowNavigation(),
          child: PageView.builder(
            controller: pageController,
            itemCount: PageState.quranPageCount,
            allowImplicitScrolling: false,
            physics: const PageScrollPhysics(),
            onPageChanged: (index) => onPageChanged(index + 1),
            itemBuilder: (_, index) => QuranImagePage(
              key: ValueKey<int>(index + 1),
              pageNumber: index + 1,
              headerImageFilter: headerImageFilter,
            ),
          ),
        );
      },
    );
  }
}
