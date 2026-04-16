import 'package:flutter/material.dart';

import '../../../core/design_tokens/design_tokens.dart';
import '../../../core/perf_logger.dart';
import '../../../domain/domain.dart';
import '../molecules/molecules.dart';

/// Organism component for the navigation slider overlay.
///
/// This is a complex widget that combines:
/// - Navigation button group (previous/next + page indicator)
/// - Page slider for fast navigation
/// - Fade in/out animations
/// - Gesture detection for interaction
class NavigationSliderOverlay extends StatelessWidget {
  const NavigationSliderOverlay({
    super.key,
    required this.screenWidth,
    required this.state,
    required this.canGoToPreviousPage,
    required this.canGoToNextPage,
    required this.onPreviewPageChanged,
    required this.onPageNavigationRequested,
    required this.onPreviousPageRequested,
    required this.onNextPageRequested,
    required this.onInteractionStart,
    required this.onInteractionEnd,
  });

  final double screenWidth;
  final PageState state;
  final bool canGoToPreviousPage;
  final bool canGoToNextPage;
  final ValueChanged<int> onPreviewPageChanged;
  final ValueChanged<int> onPageNavigationRequested;
  final VoidCallback onPreviousPageRequested;
  final VoidCallback onNextPageRequested;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bool isLandscape = screenWidth > screenHeight;
    final double effectiveHeight = isLandscape
        ? screenWidth // use longer side for sizing in landscape
        : screenHeight;
    final sliderHeight = effectiveHeight * AppDimensions.sliderHeightRatio;
    final horizontalPadding =
        screenWidth * AppDimensions.sliderHorizontalPaddingRatio;
    final bottomMargin = screenHeight * AppDimensions.sliderBottomMarginRatio;
    final borderRadius = screenWidth * AppDimensions.sliderBorderRadiusRatio;

    // Static decoration container stays outside BlocBuilder so it is not
    // recreated on every displayPage tick during slider drags.
    return GestureDetector(
      onTapDown: (_) => onInteractionStart(),
      onTapUp: (_) => onInteractionEnd(),
      onHorizontalDragStart: (_) => onInteractionStart(),
      onHorizontalDragEnd: (_) => onInteractionEnd(),
      child: Container(
        margin: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          bottom: bottomMargin,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: sliderHeight * 0.1,
        ),
        decoration: BoxDecoration(
          color: AppColors.sliderBackground.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Builder(
          builder: (context) {
            final sw = PerfLogger.startTimer();
            final content = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PageSlider(
                  currentPage: state.displayPage,
                  totalPages: state.totalPages,
                  onChanged: (value) => onPreviewPageChanged(value.round()),
                  onChangeEnd: (value) =>
                      onPageNavigationRequested(value.round()),
                  screenWidth: screenWidth,
                ),
                SizedBox(height: sliderHeight * 0.15),
                NavigationButtonGroup(
                  currentPage: state.displayPage,
                  totalPages: state.totalPages,
                  onPrevious: canGoToPreviousPage
                      ? onPreviousPageRequested
                      : null,
                  onNext: canGoToNextPage ? onNextPageRequested : null,
                  screenWidth: screenWidth,
                ),
              ],
            );
            PerfLogger.logElapsed(
              sw,
              widgetName: 'NavigationSliderOverlay',
              message:
                  'build displayPage=${state.displayPage} '
                  'currentPage=${state.currentPage}',
            );
            return content;
          },
        ),
      ),
    );
  }
}
