import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image_flutter/core/design_tokens/design_tokens.dart';
import 'package:quran_image_flutter/domain/entities/page_state.dart';
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

  @override
  void initState() {
    super.initState();
    final currentState = context.read<NavigationBloc>().state;
    final initialIndex = currentState is NavigationLoaded
        ? currentState.pageState.pageIndex
        : 0;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 86.33333333),
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
                  if (_pageController.hasClients &&
                      _pageController.page?.round() != targetIndex) {
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
              child: GestureDetector(
                onTap: () => context.read<NavigationBloc>().add(
                  const NavigationToggled(),
                ),
                onVerticalDragStart: (_) =>
                    context.read<NavigationBloc>().add(const NavigationShown()),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: PageState.quranPageCount,
                  allowImplicitScrolling: false,
                  physics: const PageScrollPhysics(),
                  onPageChanged: (index) {
                    context.read<NavigationBloc>().add(PageChanged(index + 1));
                  },
                  itemBuilder: (_, index) {
                    return QuranImagePage(pageNumber: index + 1);
                  },
                ),
              ),
            ),

            // Premium Navigation Overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BlocBuilder<NavigationBloc, NavigationState>(
                builder: (context, state) {
                  if (state is! NavigationLoaded) {
                    return const SizedBox.shrink();
                  }

                  final isVisible = state.visibility.isVisible;

                  return AnimatedSlide(
                    offset: isVisible ? Offset.zero : const Offset(0, 1),
                    duration: const Duration(
                      milliseconds: AppDurations.sliderShowHide,
                    ),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: isVisible ? 1.0 : 0.0,
                      duration: isVisible
                          ? const Duration(
                              milliseconds: AppDurations.sliderFadeIn,
                            )
                          : const Duration(
                              milliseconds: AppDurations.sliderFadeOut,
                            ),
                      child: IgnorePointer(
                        ignoring: !isVisible,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Re-adding the slider for page jumps
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return NavigationSliderOverlay(
                                  screenWidth: constraints.maxWidth,
                                  screenHeight: MediaQuery.of(
                                    context,
                                  ).size.height,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            PremiumBottomBar(state: state.pageState),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TactileNoiseBackground extends StatelessWidget {
  static final _painter = _NoisePainter();

  const _TactileNoiseBackground();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: CustomPaint(painter: _painter));
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
