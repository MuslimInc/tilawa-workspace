import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/core/quran_image_jump_debug.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/quran_image_page.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
        if (kDebugMode) {
          PerfLogger.log(
            widgetName: 'QuranImageReader Layout Builder',
            message:
                'LayoutBuilder constraints=$constraints '
                'maxWidth=${constraints.maxWidth} '
                'maxHeight=${constraints.maxHeight}',
          );
        }
        final double viewportWidth = constraints.maxWidth;
        final double viewportHeight = constraints.maxHeight;
        final bool isLandscape = viewportWidth > viewportHeight;
        final bool dual = MushafSpreadLayout.shouldUseDualPage(
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
        );
        // Stable outer gutters on the viewport — not per-page pads driven by
        // page.floor(). Per-page start/end pads flip when startSideIndex
        // advances (dual swipe jank: content teleports by outerPad).
        final double inset = MushafSpreadLayout.horizontalInset(
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
        );

        // #region agent log
        quranImageJumpLog(
          'viewportInset',
          hypothesisId: 'H1',
          location: 'quran_reader_viewport.dart:build',
          data: <String, Object?>{
            'dual': dual,
            'inset': inset.round(),
            'viewportW': viewportWidth.round(),
            'viewportH': viewportHeight.round(),
            'spreadW': MushafSpreadLayout.spreadContentWidth(
              viewportWidth: viewportWidth,
              viewportHeight: viewportHeight,
            ).round(),
          },
        );
        // #endregion

        // Always keep Padding in the tree (inset may be 0) so dual↔single
        // rebuilds do not remount PageView under a different parent — that
        // briefly attaches two positions to one PageController and crashes
        // any `.page` read.
        return GestureDetector(
          onTap: onToggleNavigation,
          onVerticalDragStart: isLandscape ? null : (_) => onShowNavigation(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: PageView.builder(
              key: const ValueKey<String>('quran-image-page-view'),
              controller: pageController,
              itemCount: PageState.quranPageCount,
              // Dual: keep adjacent page subtree alive so swipe does not
              // cold-init a full 15-line page mid-gesture (H3).
              allowImplicitScrolling: dual,
              padEnds: false,
              physics: const PageScrollPhysics(),
              onPageChanged: (index) => onPageChanged(index + 1),
              itemBuilder: (context, index) {
                return QuranImagePage(
                  key: ValueKey<int>(index + 1),
                  pageNumber: index + 1,
                  headerImageFilter: headerImageFilter,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
