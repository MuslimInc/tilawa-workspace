import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'preloading_screen.dart';
import 'presentation/presentation.dart';
import 'verse_marker.dart';
import 'verse_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Full-screen immersive mode (hides status bar and navigation bar)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize with debug mode and preloading
  await verseService.init(forceDebugSource: true, preloadAllPages: true);

  runApp(const QuranImageApp());
}

class QuranImageApp extends StatefulWidget {
  const QuranImageApp({super.key});

  @override
  State<QuranImageApp> createState() => _QuranImageAppState();
}

class _QuranImageAppState extends State<QuranImageApp> {
  bool _isPreloaded = false;

  @override
  void initState() {
    super.initState();
    // Check if already preloaded (production mode) or needs waiting
    _isPreloaded = !verseService.isDebugMode || verseService.isPreloaded;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Image',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: _isPreloaded
          ? BlocProvider(
              create: (_) =>
                  NavigationBloc()..add(const NavigationInitialized()),
              child: const QuranImageReader(),
            )
          : PreloadingScreen(
              onPreloadComplete: () {
                setState(() {
                  _isPreloaded = true;
                });
              },
            ),
    );
  }
}

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

/// Renders a full Quran page using the same layout algorithm as the Ayah app.
///
/// The Ayah app's `QuranLineLayout` (Kotlin) places each line at:
///   y = floor((pageHeight - lineHeight) / 14 * lineIndex)
/// where:
///   lineHeight = pageWidth * 174 / 1080
///   lineIndex  = 0-based (0–14)
///
/// Each line image is the same 1440×232 aspect ratio → ratio = 232/1440 ≈ 0.1611.
class QuranImagePage extends StatelessWidget {
  static const double _lineHeightRatio = 174.0 / 1080.0;
  static const int _lineCount = 15;

  final int pageNumber;

  const QuranImagePage({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final markers = verseService.getMarkersForPage(pageNumber);

    return Padding(
      padding: const EdgeInsets.only(top: 19, bottom: 19),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double pageWidth = constraints.maxWidth;
          final double pageHeight = constraints.maxHeight;
          final double lineHeight = pageWidth * _lineHeightRatio;

          const double lastLineIndex = _lineCount - 1;
          final List<double> yOffsets = List.generate(_lineCount, (i) {
            return ((pageHeight - lineHeight) / lastLineIndex * i)
                .floorToDouble();
          });

          return Stack(
            children: [
              for (var i = 0; i < _lineCount; i++)
                Positioned(
                  left: 0,
                  right: 0,
                  top: yOffsets[i],
                  height: lineHeight,
                  child: RepaintBoundary(
                    child: Image.asset(
                      'assets/quran_images/$pageNumber/${i + 1}.png',
                      fit: BoxFit.fill,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),

              for (final marker in markers)
                _AyahMarkerWidget(
                  marker: marker,
                  pageWidth: pageWidth,
                  pageHeight: pageHeight,
                  lineHeight: lineHeight,
                  yOffsets: yOffsets,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AyahMarkerWidget extends StatelessWidget {
  final VerseMarkerData marker;
  final double pageWidth;
  final double pageHeight;
  final double lineHeight;
  final List<double> yOffsets;

  const _AyahMarkerWidget({
    required this.marker,
    required this.pageWidth,
    required this.pageHeight,
    required this.lineHeight,
    required this.yOffsets,
  });

  @override
  Widget build(BuildContext context) {
    // Precise: Based on Ayah app measurement of 37x47 px on a 720 px-wide screen.
    final double markerW = pageWidth * 0.05138889;
    final double markerH = pageWidth * 0.06527778;

    final double xOffset = marker.centerX * pageWidth - markerW / 2;

    // marker.line is the 0-based image-file index (0–14).
    // yCenter = top of that line's slot + half a line height (vertical centre).
    final int idx = marker.line.clamp(0, 14);
    final double yCenter = yOffsets[idx] + lineHeight / 2;

    return Positioned(
      left: xOffset,
      top: yCenter - markerH / 2,
      child: VerseMarker(
        verseNumber: marker.ayah,
        width: markerW,
        height: markerH,
      ),
    );
  }
}
