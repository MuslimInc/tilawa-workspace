import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image_flutter/presentation/presentation.dart';
import 'package:quran_image_flutter/quran_image_page.dart';

class QuranImageReader extends StatefulWidget {
  const QuranImageReader({super.key});

  @override
  State<QuranImageReader> createState() => _QuranImageReaderState();
}

class _QuranImageReaderState extends State<QuranImageReader> {
  final PageController _pageController = PageController(initialPage: 603);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF4E4),
      body: BlocListener<NavigationBloc, NavigationState>(
        listenWhen: (previous, current) {
          // Only listen when page number changes
          if (previous is NavigationLoaded && current is NavigationLoaded) {
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

              // For large jumps (>3 pages), use jumpToPage to avoid
              // building intermediate pages. For small jumps, use animation.
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
          onTap: () =>
              context.read<NavigationBloc>().add(const NavigationToggled()),
          onVerticalDragStart: (_) =>
              context.read<NavigationBloc>().add(const NavigationShown()),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: 604,
                // Optimize: disable pre-fetching of adjacent pages
                allowImplicitScrolling: false,
                physics: const PageScrollPhysics(),
                onPageChanged: (index) {
                  context.read<NavigationBloc>().add(PageChanged(index + 1));
                },
                itemBuilder: (_, index) =>
                    QuranImagePage(pageNumber: index + 1),
              ),
              // Navigation Controls Overlay (Pill + Slider)
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

                    return AnimatedOpacity(
                      opacity: isVisible ? 1.0 : 0.0,
                      duration: isVisible
                          ? const Duration(milliseconds: 250)
                          : const Duration(milliseconds: 350),
                      child: IgnorePointer(
                        ignoring: !isVisible,
                        child: GestureDetector(
                          onTapDown: (_) => context.read<NavigationBloc>().add(
                            const NavigationInteractionStarted(),
                          ),
                          onTapUp: (_) => context.read<NavigationBloc>().add(
                            const NavigationInteractionEnded(),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pill Page Indicator (above slider)
                              PillPageIndicator(
                                pageNumber: state.pageState.displayPage,
                                screenWidth: MediaQuery.of(context).size.width,
                              ),
                              const SizedBox(height: 12),
                              // Navigation Slider
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
      ),
    );
  }
}
