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
  });

  final ValueListenable<PageState?> previewStateListenable;
  final ValueChanged<int> onPreviewPageChanged;
  final ValueChanged<int> onPageNavigationRequested;
  final VoidCallback onPreviousPageRequested;
  final VoidCallback onNextPageRequested;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;
  final VoidCallback? onShareRequested;

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
  });

  final ValueListenable<PageState?> previewStateListenable;
  final ValueChanged<int> onPreviewPageChanged;
  final ValueChanged<int> onPageNavigationRequested;
  final VoidCallback onPreviousPageRequested;
  final VoidCallback onNextPageRequested;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;
  final VoidCallback? onShareRequested;

  @override
  Widget build(BuildContext context) {
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
                          if (onShareRequested != null) ...[
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
                                    child: _PremiumShareFab(
                                      onTap: onShareRequested!,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: tokens.spaceSmall),
                          ],
                          RepaintBoundary(
                            child: NavigationSliderOverlay(
                              screenWidth: constraints.maxWidth,
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

class _PremiumShareFab extends StatelessWidget {
  const _PremiumShareFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return SizedBox.square(
      dimension: tokens.iconSizeExtraLarge,
      child: FloatingActionButton.small(
        heroTag: null,
        elevation: tokens.spaceTiny,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
        ),
        onPressed: onTap,
        child: Icon(
          Icons.video_camera_back_outlined,
          size: tokens.iconSizeMedium,
        ),
      ),
    );
  }
}
