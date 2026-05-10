import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
    required this.committedPage,
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
  final int committedPage;
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
    PerfLogger.markBuild('NavigationSliderOverlay');
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final componentTokens = theme.extension<TilawaComponentTokens>();
    final bottomInset = context.systemBottomSafeArea;
    final panelRadius = BorderRadius.circular(
      tokens.radiusExtraLarge + tokens.spaceSmall,
    );
    final panelPadding = EdgeInsets.fromLTRB(
      tokens.spaceLarge,
      tokens.spaceMedium,
      tokens.spaceLarge,
      tokens.spaceLarge,
    );

    return GestureDetector(
      onTapDown: (_) => onInteractionStart(),
      onTapUp: (_) => onInteractionEnd(),
      onHorizontalDragStart: (_) => onInteractionStart(),
      onHorizontalDragEnd: (_) => onInteractionEnd(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          0,
          tokens.spaceLarge,
          bottomInset + tokens.spaceMedium,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: tokens.contentMaxWidthForm),
            child: Builder(
              builder: (context) {
                final content = Builder(
                  builder: (context) {
                    final sw = PerfLogger.startTimer();
                    final content = Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PageSlider(
                          currentPage: state.displayPage,
                          committedPage: committedPage,
                          totalPages: state.totalPages,
                          onChanged: (value) =>
                              onPreviewPageChanged(value.round()),
                          onChangeEnd: (value) =>
                              onPageNavigationRequested(value.round()),
                          screenWidth: screenWidth,
                        ),
                        SizedBox(height: tokens.spaceMedium),
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
                );

                if (componentTokens != null) {
                  return TilawaGlassPanel(
                    enableBackdropBlur: true,
                    borderRadius: panelRadius,
                    backgroundColor: colorScheme.surface.withValues(
                      alpha: tokens.opacityGlass,
                    ),
                    borderColor: colorScheme.primary.withValues(
                      alpha: tokens.opacityMedium,
                    ),
                    padding: panelPadding,
                    child: content,
                  );
                }

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(
                      alpha: tokens.opacityGlass,
                    ),
                    borderRadius: panelRadius,
                    border: Border.all(
                      color: colorScheme.primary.withValues(
                        alpha: tokens.opacityMedium,
                      ),
                    ),
                  ),
                  child: Padding(padding: panelPadding, child: content),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
