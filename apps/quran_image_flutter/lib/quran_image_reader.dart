import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image_flutter/core/constants/surah_header_constants.dart';
import 'package:quran_image_flutter/core/design_tokens/design_tokens.dart';
import 'package:quran_image_flutter/core/di/dependency_injection.dart';
import 'package:quran_image_flutter/core/perf_logger.dart';
import 'package:quran_image_flutter/domain/entities/page_state.dart';
import 'package:quran_image_flutter/domain/repositories/quran_image_cache_repository.dart';
import 'package:quran_image_flutter/presentation/presentation.dart';
import 'package:quran_image_flutter/presentation/widgets/premium_bottom_bar.dart';
import 'package:quran_image_flutter/quran_image_page.dart';

class QuranImageReader extends StatefulWidget {
  const QuranImageReader({super.key});

  @override
  State<QuranImageReader> createState() => _QuranImageReaderState();
}

class _QuranImageReaderState extends State<QuranImageReader> {
  late final PageController _pageController;
  late int _lastSettledPageIndex;

  // How many pages ahead/behind to pre-warm into Flutter's image cache.
  static const int _prewarmRadius = 1;

  // Track the last center page we pre-warmed to avoid redundant work on every
  // scroll tick when the nearest page hasn't changed.
  int _lastPrewarmedCenter = -1;
  int _lastPrewarmedCacheWidth = -1;

  @override
  void initState() {
    super.initState();
    final currentState = context.read<NavigationBloc>().state;
    final initialIndex = currentState is NavigationLoaded
        ? currentState.pageState.pageIndex
        : 0;
    _lastSettledPageIndex = initialIndex;
    _pageController = PageController(initialPage: initialIndex);

    // Listen on every scroll position change so we pre-warm the destination
    // page images *during* the swipe, not only after it settles.
    _pageController.addListener(_onScrollPositionChanged);

    // Pre-warm the initial page and its neighbours after the first frame so we
    // don't block the initial build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prewarmAround(initialIndex + 1);
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScrollPositionChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// Called on every scroll tick. Computes the nearest page and pre-warms it
  /// if it differs from the last pre-warmed center — avoiding redundant work.
  void _onScrollPositionChanged() {
    final page = _pageController.page;
    if (page == null) return;
    // Round to nearest page index (0-based) then convert to 1-based page number.
    final nearest = page.round() + 1;
    _prewarmAround(nearest);
  }

  /// Pre-warms [_prewarmRadius] pages on each side of [centerPageNumber] by
  /// pushing all their line images into Flutter's [ImageCache] ahead of time.
  ///
  /// Decoding happens off the raster thread (Impeller/Skia's image decoder)
  /// while the current page is already visible, so the next page arrives
  /// pre-decoded and renders in a single frame instead of 15+ frames.
  void _prewarmAround(int centerPageNumber) {
    final repo = sl<QuranImageCacheRepository>();
    if (!repo.status.isReady) return;

    // Compute cacheWidth from the current device pixel ratio and screen width.
    // This must match the cacheWidth used in _QuranLineImage exactly, otherwise
    // Flutter will decode a second copy at a different resolution.
    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    final screenWidth = view.physicalSize.width / dpr;
    final cacheWidth = (screenWidth * dpr).round();
    if (_lastPrewarmedCenter == centerPageNumber &&
        _lastPrewarmedCacheWidth == cacheWidth) {
      return;
    }

    _lastPrewarmedCenter = centerPageNumber;
    _lastPrewarmedCacheWidth = cacheWidth;

    final first = (centerPageNumber - _prewarmRadius).clamp(
      1,
      PageState.quranPageCount,
    );
    final last = (centerPageNumber + _prewarmRadius).clamp(
      1,
      PageState.quranPageCount,
    );

    PerfLogger.log('[Prewarm] pages $first–$last  cacheWidth=$cacheWidth');

    for (var page = first; page <= last; page++) {
      for (var line = 1; line <= SurahHeaderConstants.lineCount; line++) {
        final path = repo.lineImageFilePath(
          pageNumber: page,
          oneBasedLineNumber: line,
        );
        if (path == null) continue;

        // precacheImage pushes the image through Flutter's codec pipeline and
        // into the ImageCache. Errors are silently swallowed — a missing file
        // will just fall through to the normal error handler in _QuranLineImage.
        precacheImage(
          buildQuranLineImageProvider(imagePath: path, cacheWidth: cacheWidth),
          context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Padding(
        padding: EdgeInsets.only(
          top: padding.top,
          bottom: padding.bottom,
          left: padding.left,
          right: padding.right,
        ),
        child: Stack(
          children: [
            // Background Noise Texture
            const Positioned.fill(child: _TactileNoiseBackground()),

            BlocListener<NavigationBloc, NavigationState>(
              listenWhen: (previous, current) {
                if (previous is NavigationLoaded &&
                    current is NavigationLoaded) {
                  return previous.pageState.currentPage !=
                      current.pageState.currentPage;
                }
                return false;
              },
              listener: (context, state) {
                if (state is NavigationLoaded) {
                  final targetIndex = state.pageState.pageIndex;
                  if (targetIndex == _lastSettledPageIndex) {
                    return;
                  }

                  if (_pageController.hasClients) {
                    final currentIndex = _pageController.page?.round() ?? 0;
                    final delta = (targetIndex - currentIndex).abs();

                    if (delta > 3) {
                      _pageController.jumpToPage(targetIndex);
                    } else {
                      _pageController.animateToPage(
                        targetIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isLandscape =
                      constraints.maxWidth > constraints.maxHeight;
                  return GestureDetector(
                    onTap: () => context.read<NavigationBloc>().add(
                      const NavigationToggled(),
                    ),
                    // In landscape, vertical drags scroll page content.
                    onVerticalDragStart: isLandscape
                        ? null
                        : (_) => context.read<NavigationBloc>().add(
                            const NavigationShown(),
                          ),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: PageState.quranPageCount,
                      allowImplicitScrolling: false,
                      physics: const PageScrollPhysics(),
                      onPageChanged: (index) {
                        _lastSettledPageIndex = index;
                        PerfLogger.log(
                          '[PageView] swiped to page ${index + 1}',
                        );
                        context.read<NavigationBloc>().add(
                          PageChanged(index + 1),
                        );
                        // Pre-warm the pages around the newly settled page.
                        _prewarmAround(index + 1);
                      },
                      itemBuilder: (_, index) =>
                          _KeepAliveQuranPage(pageNumber: index + 1),
                    ),
                  );
                },
              ),
            ),

            const _PremiumNavigationOverlay(),
          ],
        ),
      ),
    );
  }
}

class _PremiumNavigationOverlay extends StatelessWidget {
  const _PremiumNavigationOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: BlocSelector<NavigationBloc, NavigationState, bool>(
        selector: (state) {
          return state is NavigationLoaded && state.visibility.isVisible;
        },
        builder: (context, isVisible) {
          return AnimatedSlide(
            offset: isVisible ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: AppDurations.sliderShowHide),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(
              ignoring: !isVisible,
              child: const RepaintBoundary(child: _PremiumNavigationControls()),
            ),
          );
        },
      ),
    );
  }
}

class _PremiumNavigationControls extends StatelessWidget {
  const _PremiumNavigationControls();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return NavigationSliderOverlay(screenWidth: constraints.maxWidth);
          },
        ),
        const SizedBox(height: 8),
        BlocSelector<NavigationBloc, NavigationState, PageState?>(
          selector: (state) {
            return state is NavigationLoaded ? state.pageState : null;
          },
          builder: (context, pageState) {
            if (pageState == null) {
              return const SizedBox.shrink();
            }
            return PremiumBottomBar(state: pageState);
          },
        ),
      ],
    );
  }
}

class _TactileNoiseBackground extends StatelessWidget {
  static final _painter = _NoisePainter();

  const _TactileNoiseBackground();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: _painter, isComplex: true, willChange: false),
    );
  }
}

class _KeepAliveQuranPage extends StatefulWidget {
  const _KeepAliveQuranPage({required this.pageNumber});

  final int pageNumber;

  @override
  State<_KeepAliveQuranPage> createState() => _KeepAliveQuranPageState();
}

class _KeepAliveQuranPageState extends State<_KeepAliveQuranPage>
    with AutomaticKeepAliveClientMixin<_KeepAliveQuranPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return QuranImagePage(pageNumber: widget.pageNumber);
  }
}

class _NoisePainter extends CustomPainter {
  static List<Offset>? _cachedPoints;
  static Size? _cachedSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedPoints == null || _cachedSize != size) {
      final random = math.Random(42);
      _cachedPoints = List.generate(2000, (_) {
        return Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        );
      });
      _cachedSize = size;
    }

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.02)
      ..strokeWidth = 1.0;

    canvas.drawPoints(PointMode.points, _cachedPoints!, paint);
  }

  @override
  bool shouldRepaint(oldDelegate) => false;
}
