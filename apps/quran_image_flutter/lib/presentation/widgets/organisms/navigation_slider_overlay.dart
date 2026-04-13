import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_tokens/design_tokens.dart';
import '../../bloc/bloc.dart';
import '../molecules/molecules.dart';

/// Organism component for the navigation slider overlay.
///
/// This is a complex widget that combines:
/// - Navigation button group (previous/next + page indicator)
/// - Page slider for fast navigation
/// - Fade in/out animations
/// - Gesture detection for interaction
class NavigationSliderOverlay extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const NavigationSliderOverlay({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (previous, current) {
        if (previous is NavigationLoaded && current is NavigationLoaded) {
          return previous.pageState.displayPage !=
                  current.pageState.displayPage ||
              previous.pageState.currentPage != current.pageState.currentPage;
        }
        return previous != current;
      },
      builder: (context, state) {
        if (state is! NavigationLoaded) {
          return const SizedBox.shrink();
        }

        final pageState = state.pageState;

        final bool isLandscape = screenWidth > screenHeight;
        final double effectiveHeight = isLandscape
            ? screenWidth // use longer side for sizing in landscape
            : screenHeight;
        final sliderHeight = effectiveHeight * AppDimensions.sliderHeightRatio;
        final horizontalPadding =
            screenWidth * AppDimensions.sliderHorizontalPaddingRatio;
        final bottomMargin =
            screenHeight * AppDimensions.sliderBottomMarginRatio;
        final borderRadius =
            screenWidth * AppDimensions.sliderBorderRadiusRatio;

        return GestureDetector(
          onTapDown: (_) => _onInteractionStart(context),
          onTapUp: (_) => _onInteractionEnd(context),
          onHorizontalDragStart: (_) => _onInteractionStart(context),
          onHorizontalDragEnd: (_) => _onInteractionEnd(context),
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Page Slider - uses displayPage for real-time updates
                PageSlider(
                  currentPage: pageState.displayPage,
                  totalPages: pageState.totalPages,
                  onChanged: (value) {
                    final page = value.round();
                    context.read<NavigationBloc>().add(PagePreviewed(page));
                  },
                  onChangeEnd: (value) => _onSliderChangeEnd(context, value),
                  screenWidth: screenWidth,
                ),
                SizedBox(height: sliderHeight * 0.15),
                // Navigation Buttons - shows displayPage for preview
                NavigationButtonGroup(
                  currentPage: pageState.displayPage,
                  totalPages: pageState.totalPages,
                  onPrevious: pageState.currentPage > 1
                      ? () => _onPreviousPage(context)
                      : null,
                  onNext: pageState.currentPage < pageState.totalPages
                      ? () => _onNextPage(context)
                      : null,
                  screenWidth: screenWidth,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onInteractionStart(BuildContext context) {
    context.read<NavigationBloc>().add(const NavigationInteractionStarted());
  }

  void _onInteractionEnd(BuildContext context) {
    context.read<NavigationBloc>().add(const NavigationInteractionEnded());
  }

  void _onSliderChangeEnd(BuildContext context, double value) {
    final page = value.round();
    context.read<NavigationBloc>().add(PageNavigated(page));
  }

  void _onPreviousPage(BuildContext context) {
    context.read<NavigationBloc>().add(const PreviousPageRequested());
  }

  void _onNextPage(BuildContext context) {
    context.read<NavigationBloc>().add(const NextPageRequested());
  }
}
