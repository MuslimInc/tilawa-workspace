import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../core/perf_logger.dart';
import '../../../domain/domain.dart';
import '../../bloc/bloc.dart';
import 'navigation_slider_overlay.dart';

class PremiumNavigationOverlay extends StatefulWidget {
  const PremiumNavigationOverlay({
    super.key,
    required this.previewStateListenable,
    required this.onPreviewPageChanged,
    required this.onPageNavigationRequested,
    required this.onPreviousPageRequested,
    required this.onNextPageRequested,
    required this.onInteractionStart,
    required this.onInteractionEnd,
    this.onShareRequested,
    this.onShowIndex,
  });

  final ValueListenable<PageState?> previewStateListenable;
  final ValueChanged<int> onPreviewPageChanged;
  final ValueChanged<int> onPageNavigationRequested;
  final VoidCallback onPreviousPageRequested;
  final VoidCallback onNextPageRequested;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;
  final VoidCallback? onShareRequested;
  final VoidCallback? onShowIndex;

  @override
  State<PremiumNavigationOverlay> createState() =>
      _PremiumNavigationOverlayState();
}

class _PremiumNavigationOverlayState extends State<PremiumNavigationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  bool _hasBeenShown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final navState = context.read<NavigationBloc>().state;
    if (navState is NavigationLoaded && navState.visibility.isVisible) {
      _controller.value = 1.0;
      _hasBeenShown = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = Theme.of(context).tokens.durationMedium;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(bool isVisible) {
    if (isVisible) {
      if (!_hasBeenShown) {
        setState(() {
          _hasBeenShown = true;
        });
      }
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: BlocListener<NavigationBloc, NavigationState>(
        listenWhen: (previous, current) {
          if (previous is NavigationLoaded && current is NavigationLoaded) {
            return previous.visibility.isVisible !=
                current.visibility.isVisible;
          }
          return false;
        },
        listener: (context, state) {
          if (state is NavigationLoaded) {
            _onVisibilityChanged(state.visibility.isVisible);
          }
        },
        child: SlideTransition(
          position: _slideAnimation,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return IgnorePointer(
                ignoring: _controller.value == 0.0,
                child: child,
              );
            },
            child: RepaintBoundary(
              child: _hasBeenShown
                  ? _PremiumNavigationControls(
                      previewStateListenable: widget.previewStateListenable,
                      onPreviewPageChanged: widget.onPreviewPageChanged,
                      onPageNavigationRequested:
                          widget.onPageNavigationRequested,
                      onPreviousPageRequested: widget.onPreviousPageRequested,
                      onNextPageRequested: widget.onNextPageRequested,
                      onInteractionStart: widget.onInteractionStart,
                      onInteractionEnd: widget.onInteractionEnd,
                      onShareRequested: widget.onShareRequested,
                      onShowIndex: widget.onShowIndex,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumNavigationControls extends StatelessWidget {
  const _PremiumNavigationControls({
    required this.previewStateListenable,
    required this.onPreviewPageChanged,
    required this.onPageNavigationRequested,
    required this.onPreviousPageRequested,
    required this.onNextPageRequested,
    required this.onInteractionStart,
    required this.onInteractionEnd,
    this.onShareRequested,
    this.onShowIndex,
  });

  final ValueListenable<PageState?> previewStateListenable;
  final ValueChanged<int> onPreviewPageChanged;
  final ValueChanged<int> onPageNavigationRequested;
  final VoidCallback onPreviousPageRequested;
  final VoidCallback onNextPageRequested;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;
  final VoidCallback? onShareRequested;
  final VoidCallback? onShowIndex;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('PremiumNavigationControls');
    final sw = PerfLogger.startTimer();
    final controls = BlocSelector<NavigationBloc, NavigationState, PageState?>(
      selector: (state) {
        return state is NavigationLoaded ? state.pageState : null;
      },
      builder: (context, committedPageState) {
        if (committedPageState == null) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<PageState?>(
          valueListenable: previewStateListenable,
          builder: (context, previewPageState, _) {
            final effectivePageState = previewPageState ?? committedPageState;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tokens = Theme.of(context).tokens;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Surah-index FAB, floating just above the page card.
                          if (onShowIndex != null) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: tokens.spaceLarge,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: tokens.contentMaxWidthForm,
                                  ),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: _PremiumIndexFab(
                                      onTap: onShowIndex!,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: tokens.spaceSmall),
                          ],
                          /// TODO[feature]: Disable this feature for now because it is not stable yet, and we want to focus on getting the core navigation experience right first. We can re-enable it once it's more polished.
                          // if (onShareRequested != null) ...[
                          //   Padding(
                          //     padding: EdgeInsets.symmetric(
                          //       horizontal: tokens.spaceLarge,
                          //     ),
                          //     child: Center(
                          //       child: ConstrainedBox(
                          //         constraints: BoxConstraints(
                          //           maxWidth: tokens.contentMaxWidthForm,
                          //         ),
                          //         child: Align(
                          //           alignment: AlignmentDirectional.centerEnd,
                          //           child: _PremiumShareFab(
                          //             onTap: onShareRequested!,
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          //   SizedBox(height: tokens.spaceSmall),
                          // ],
                          RepaintBoundary(
                            child: NavigationSliderOverlay(
                              screenWidth: constraints.maxWidth,
                              committedPage: committedPageState.currentPage,
                              state: effectivePageState,
                              canGoToPreviousPage:
                                  committedPageState.currentPage > 1,
                              canGoToNextPage:
                                  committedPageState.currentPage <
                                  committedPageState.totalPages,
                              onPreviewPageChanged: onPreviewPageChanged,
                              onPageNavigationRequested:
                                  onPageNavigationRequested,
                              onPreviousPageRequested: onPreviousPageRequested,
                              onNextPageRequested: onNextPageRequested,
                              onInteractionStart: onInteractionStart,
                              onInteractionEnd: onInteractionEnd,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    PerfLogger.logElapsed(
      sw,
      widgetName: 'PremiumNavigationControls',
      message: 'build',
    );
    return controls;
  }
}

/// Circular floating button that opens the host's surah index, sitting just
/// above the page navigation card. Mirrors the bottom bar's button styling but
/// adds elevation so it reads as a floating action.
class _PremiumIndexFab extends StatelessWidget {
  const _PremiumIndexFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final double size = tokens.iconSizeExtraLarge;

    return Semantics(
      button: true,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: tokens.opacityMedium),
        shape: CircleBorder(
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: tokens.opacityMedium),
            width: tokens.borderWidthThin,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.list_rounded,
              size: tokens.iconSizeMedium,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
