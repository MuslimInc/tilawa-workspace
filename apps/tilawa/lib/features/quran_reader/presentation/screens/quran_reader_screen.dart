import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_index_sheet.dart';
import 'package:tilawa/features/share/presentation/cubit/share_cubit.dart';
import 'package:tilawa/features/share/presentation/screens/share_composer_screen.dart';

import '../../../../core/presentation/cubit/ui_visibility_cubit.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../bloc/quran_reader_bloc.dart';

/// Screen for reading Quran text in a page-by-page Mushaf view.
///
/// Displays [QuranPageView] with a floating action button to open
/// the surah index sheet for quick navigation.
class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  /// The surah number to open initially.
  final int surahNumber;

  /// Optional initial ayah to scroll to.
  final int? initialAyah;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  late final ValueNotifier<int> _currentPageNotifier;
  late final UiVisibilityCubit _uiVisibilityCubit;
  bool _didInitDependencies = false;
  bool _isInitialPageJumpDone = false;
  final GlobalKey _pageViewKey = GlobalKey();
  final GlobalKey _screenshotBoundaryKey = GlobalKey();

  static const _headerFontSizeMultiplier = 0.57;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Enable landscape and portrait for this screen only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _uiVisibilityCubit = context.read<UiVisibilityCubit>();

    // Ensure UI is visible when entering the reader
    _uiVisibilityCubit.show();

    // Pause audio playback for a distraction-free reading experience
    final audioBloc = context.read<AudioPlayerBloc>();
    if (audioBloc.state.isPlaying) {
      audioBloc.add(const AudioPlayerEvent.pauseAudio());
    }

    int initialPage = 1;

    if (widget.surahNumber > 0) {
      initialPage = getPageNumber(widget.surahNumber, 1);
      // Save last-read position. Use loadSurah with loadStartPage: false
      // so it only updates surah metadata — the PageController already
      // starts at the correct page via initialPage, so we must NOT
      // trigger loadPage which would cause an async round-trip and
      // a redundant jumpToPage via the BlocListener.
      final bloc = context.read<QuranReaderBloc>();
      if (bloc.state.currentSurah?.number != widget.surahNumber) {
        bloc.add(
          QuranReaderEvent.loadSurah(widget.surahNumber, loadStartPage: false),
        );
      }
      bloc.add(
        QuranReaderEvent.saveLastRead(
          surahNumber: widget.surahNumber,
          page: initialPage,
        ),
      );
    } else {
      // For last read (surahNumber == 0), check if the global bloc already has a page
      final currentState = context.read<QuranReaderBloc>().state;
      if (currentState.currentPage != null) {
        initialPage = currentState.currentPage!.pageNumber;
        _isInitialPageJumpDone = true;
      }
    }

    _currentPageNotifier = ValueNotifier<int>(initialPage);
    _pageController = PageController(initialPage: initialPage - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitDependencies) {
      _didInitDependencies = true;
      _enterReaderImmersiveMode();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _currentPageNotifier.dispose();
    // Revert to portrait only when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _restoreAppSystemUiMode();
    // Ensure UI is visible when leaving the reader
    _uiVisibilityCubit.show();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enterReaderImmersiveMode();
    }
  }

  void _enterReaderImmersiveMode() {
    final readerTheme = QuranReaderTheme.of(context);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.top],
    );
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: readerTheme.systemBarColor,
        statusBarIconBrightness: readerTheme.statusBarIconBrightness,
        statusBarBrightness: readerTheme.statusBarBrightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: readerTheme.statusBarIconBrightness,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  void _restoreAppSystemUiMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle());
  }

  @override
  Widget build(BuildContext context) {
    final readerTheme = QuranReaderTheme.of(context);
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(scaffoldBackgroundColor: readerTheme.pageBackground),
      child: BlocListener<QuranReaderBloc, QuranReaderState>(
        listenWhen: (previous, current) =>
            previous.currentPage != current.currentPage &&
            current.currentPage != null,
        listener: (context, state) {
          final pageNumber = state.currentPage!.pageNumber;

          // Sync PageController ONLY if it's not already at the correct page
          if (_pageController.hasClients) {
            final currentPageInController =
                _pageController.page ?? _pageController.initialPage.toDouble();

            if ((currentPageInController + 1 - pageNumber).abs() > 0.1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients &&
                    !_pageController.position.isScrollingNotifier.value) {
                  _pageController.jumpToPage(pageNumber - 1);
                }
              });
            }
          }

          if (!_isInitialPageJumpDone) {
            if (mounted) {
              setState(() {
                _isInitialPageJumpDone = true;
              });
            }
          }
        },
        child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.errorMessage != current.errorMessage,
          builder: (context, state) {
            final ThemeData theme = Theme.of(context);
            final ColorScheme colorScheme = theme.colorScheme;

            // Show loading if we are waiting for the last read position
            if (widget.surahNumber == 0 &&
                !_isInitialPageJumpDone &&
                state.status == QuranReaderStatus.loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state.status == QuranReaderStatus.error) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: colorScheme.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        state.errorMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<QuranReaderBloc>().add(
                            const QuranReaderEvent.loadLastRead(),
                          );
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Stack(
              children: [
                Scaffold(
                  key: const ValueKey('QuranReaderScaffold'),
                  resizeToAvoidBottomInset: false,
                  body: GestureDetector(
                    onTap: () {
                      context.read<UiVisibilityCubit>().toggle();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
                      buildWhen: (oldState, newState) =>
                          oldState.settings != newState.settings ||
                          oldState.status != newState.status,
                      builder: (context, state) {
                        return RepaintBoundary(
                          key: _screenshotBoundaryKey,
                          child: QuranPageView(
                            key: _pageViewKey,
                            controller: _pageController,
                            currentPageListenable: _currentPageNotifier,
                            pageBackgroundColor: readerTheme.pageBackground,
                            textColor: readerTheme.textColor,
                            headerImageFilter: readerTheme.headerImageFilter,
                            headerTextColor: readerTheme.headerTextColor,
                            headerFontSizeMultiplier: _headerFontSizeMultiplier,
                            onPageChanged: (pageNumber) {
                              if (_currentPageNotifier.value != pageNumber) {
                                _currentPageNotifier.value = pageNumber;
                              }
                              final pageData = getPageData(pageNumber);
                              final surahNumber = pageData.first['surah']!;
                              context.read<QuranReaderBloc>().add(
                                QuranReaderEvent.saveLastRead(
                                  surahNumber: surahNumber,
                                  page: pageNumber,
                                ),
                              );
                            },
                            juzLabel: context.l10n.juzPart,
                            hizbLabel: context.l10n.hizb,
                            surahNameBuilder: (surahNumber) {
                              return context.l10n.localeName == 'ar'
                                  ? getSurahNameArabic(surahNumber)
                                  : getSurahNameEnglish(surahNumber);
                            },
                            onSurahSelected: _jumpToSurah,
                            onShowIndex: () => _showSurahIndex(context),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Page navigation slider — appears when UI chrome is visible.
                BlocBuilder<UiVisibilityCubit, bool>(
                  builder: (context, isVisible) {
                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        offset: isVisible ? Offset.zero : const Offset(0, 1),
                        child: ValueListenableBuilder<int>(
                          valueListenable: _currentPageNotifier,
                          builder: (context, currentPage, _) {
                            return _PageNavigationBar(
                              currentPage: currentPage,
                              onPageChanged: _jumpToPage,
                              onShowIndex: () => _showSurahIndex(context),
                              onShare: () =>
                                  _showShareOptions(context, currentPage),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showShareOptions(BuildContext context, int currentPage) async {
    final pageData = getPageData(currentPage);
    final primarySurahNumber = pageData.first['surah']!;
    final primarySurahEntries = pageData
        .where((entry) => entry['surah'] == primarySurahNumber)
        .toList();
    final surahNumber = primarySurahNumber;
    final firstAyah = primarySurahEntries.first['start'] ?? 1;
    final lastAyah = primarySurahEntries.last['end'] ?? firstAyah;
    final audioState = context.read<AudioPlayerBloc>().state;
    final reciterName = audioState.currentAudio?.artist ?? 'Al-Afasy';
    final serverUrl = audioState.currentAudio?.url ?? '';
    final shareCubit = context.read<ShareCubit>();
    final navigator = Navigator.of(context);
    final previewBytes = await _captureSharePreviewBytes();
    if (!mounted) return;

    await navigator.push(
      ShareComposerScreen.route(
        cubit: shareCubit,
        surahNumber: surahNumber,
        currentPage: currentPage,
        initialFromAyah: firstAyah,
        initialToAyah: lastAyah,
        reciterName: reciterName,
        reciterServerUrl: serverUrl,
        readerBoundaryKey: _screenshotBoundaryKey,
        readerPreviewBytes: previewBytes,
      ),
    );
  }

  Future<Uint8List?> _captureSharePreviewBytes() async {
    final boundary =
        _screenshotBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;

    try {
      final image = await boundary.toImage(pixelRatio: 0.4);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  void _showSurahIndex(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SurahIndexSheet(
        onSurahSelected: (surahNumber) {
          Navigator.of(context).pop();
          _jumpToSurah(surahNumber);
        },
      ),
    );
  }

  /// Navigates the [PageView] to the first page of [surahNumber].
  void _jumpToSurah(int surahNumber) {
    final int targetPage = getPageNumber(surahNumber, 1);
    _jumpToPage(targetPage);
  }

  /// Navigates the [PageView] to the given 1-based [pageNumber].
  void _jumpToPage(int pageNumber) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(pageNumber - 1);
    }

    final pageData = getPageData(pageNumber);
    final surahNumber = pageData.first['surah']!;
    context.read<QuranReaderBloc>().add(
      QuranReaderEvent.saveLastReadImmediate(
        surahNumber: surahNumber,
        page: pageNumber,
      ),
    );
  }
}

class _PagePreviewInfo {
  const _PagePreviewInfo({
    required this.surahName,
    required this.juzNumber,
    required this.hizbLabel,
  });

  final String surahName;
  final int juzNumber;
  final String hizbLabel;

  static _PagePreviewInfo fromPage(BuildContext context, int pageNumber) {
    final pageData = getPageData(pageNumber);
    final bool isArabic = context.l10n.localeName == 'ar';
    final Set<int> uniqueSurahNumbers = pageData
        .map((entry) => entry['surah']!)
        .toSet();

    final int juzNumber = getJuzNumber(
      pageData.first['surah']!,
      pageData.first['start']!,
    );

    final int? quarterNumber = pageNumber == 1 || pageNumber == 2
        ? null
        : getQuarterNumber(pageData.first['surah']!, pageData.first['start']!);

    String hizbLabelStr = '';
    if (quarterNumber != null) {
      final int hizbIndex = (quarterNumber - 1) ~/ 4 + 1;
      final int quarterInHizb = (quarterNumber - 1) % 4;

      final String prefix;
      switch (quarterInHizb) {
        case 0:
          prefix = '';
        case 1:
          prefix = '1/4 ';
        case 2:
          prefix = '1/2 ';
        case 3:
          prefix = '3/4 ';
        default:
          prefix = '';
      }
      hizbLabelStr = '$prefix${context.l10n.hizb} $hizbIndex';
    }

    return _PagePreviewInfo(
      surahName: uniqueSurahNumbers
          .map(
            (surahNumber) => isArabic
                ? getSurahNameArabic(surahNumber)
                : getSurahNameEnglish(surahNumber),
          )
          .join(' · '),
      juzNumber: juzNumber,
      hizbLabel: hizbLabelStr,
    );
  }
}

/// A bottom bar with a slider for quick page navigation and a surah index button.
class _PageNavigationBar extends StatefulWidget {
  const _PageNavigationBar({
    required this.currentPage,
    required this.onPageChanged,
    required this.onShowIndex,
    required this.onShare,
  });

  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onShowIndex;
  final VoidCallback onShare;

  @override
  State<_PageNavigationBar> createState() => _PageNavigationBarState();
}

class _PageNavigationBarState extends State<_PageNavigationBar> {
  static const int _totalPages = 604;
  static const double _sliderHeight = 32;
  static const double _sliderStageHeight = 36;
  static const double _sliderSectionRadius = 18;
  static const double _sliderThumbSize = 18;
  static const double _sliderRangeLabelWidth = 32;
  static const double _sliderRangeGap = 10;
  static const EdgeInsets _sliderSectionPadding = EdgeInsets.fromLTRB(
    12,
    8,
    12,
    6,
  );
  static const double _previewPillMinWidth = 132;
  static const double _previewPillMaxWidthFactor = 0.86;
  static const double _previewPillHorizontalPadding = 14;
  static const double _previewPillChipHorizontalPadding = 8;
  static const double _previewPillContentGap = 8;
  static const double _previewPillTopOffset = 44;
  static const Duration _pagePreviewDuration = Duration(milliseconds: 1100);
  static const EdgeInsets _barPadding = EdgeInsets.fromLTRB(14, 10, 14, 4);
  static const double _headerActionSize = 44;

  double? _sliderValueOverride;
  int? _lastPreviewPage;
  Timer? _previewHideTimer;
  bool _showFocusedPagePreview = false;
  bool _isDraggingSlider = false;

  bool get _showPreviewPill => _isDraggingSlider || _showFocusedPagePreview;

  bool get _isDragging => _isDraggingSlider;

  double get _sliderValue =>
      _sliderValueOverride ?? widget.currentPage.toDouble();

  int get _previewPage => _sliderValue.round().clamp(1, _totalPages);

  @override
  void didUpdateWidget(covariant _PageNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isDraggingSlider &&
        _sliderValueOverride != null &&
        widget.currentPage != oldWidget.currentPage) {
      setState(() {
        _sliderValueOverride = null;
      });
    }

    if (widget.currentPage != oldWidget.currentPage && !_isDraggingSlider) {
      _showCurrentPagePreview();
    }
  }

  @override
  void dispose() {
    _previewHideTimer?.cancel();
    super.dispose();
  }

  void _showCurrentPagePreview() {
    _previewHideTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _showFocusedPagePreview = true;
      _sliderValueOverride = null;
      _lastPreviewPage = widget.currentPage;
    });

    _previewHideTimer = Timer(_pagePreviewDuration, () {
      if (!mounted || _isDraggingSlider) return;

      setState(() {
        _showFocusedPagePreview = false;
        _lastPreviewPage = null;
      });
    });
  }

  void _handleSliderChangeStart(double value) {
    _previewHideTimer?.cancel();

    setState(() {
      _showFocusedPagePreview = false;
      _isDraggingSlider = true;
      _sliderValueOverride = value;
      _lastPreviewPage = value.round().clamp(1, _totalPages);
    });
  }

  void _handleSliderChanged(double value) {
    final int previewPage = value.round().clamp(1, _totalPages);

    if (previewPage != _lastPreviewPage) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _sliderValueOverride = value;
      _lastPreviewPage = previewPage;
    });
  }

  void _handleSliderChangeEnd(double value) {
    final int targetPage = value.round().clamp(1, _totalPages);
    final bool shouldNavigate = targetPage != widget.currentPage;

    setState(() {
      _isDraggingSlider = false;
      _showFocusedPagePreview = false;
      _sliderValueOverride = shouldNavigate ? targetPage.toDouble() : null;
      _lastPreviewPage = null;
    });

    if (shouldNavigate) {
      widget.onPageChanged(targetPage);
    }
  }

  double _measureTextWidth({
    required BuildContext context,
    required String text,
    required TextStyle style,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    return painter.width;
  }

  double _buildPreviewPillWidth({
    required BuildContext context,
    required String surahName,
    required int pageNumber,
    required double availableWidth,
  }) {
    final ThemeData theme = Theme.of(context);
    final TextStyle surahStyle = theme.textTheme.labelLarge!.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    );
    final TextStyle pageStyle = theme.textTheme.bodySmall!.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    final String pageLabel = '${context.l10n.page} $pageNumber';
    final double surahWidth = _measureTextWidth(
      context: context,
      text: surahName,
      style: surahStyle,
    );
    final double pageWidth = _measureTextWidth(
      context: context,
      text: pageLabel,
      style: pageStyle,
    );
    final double desiredWidth =
        (_previewPillHorizontalPadding * 2) +
        surahWidth +
        _previewPillContentGap +
        (_previewPillChipHorizontalPadding * 2) +
        pageWidth;
    final double maxWidth = availableWidth.clamp(
      _previewPillMinWidth,
      MediaQuery.sizeOf(context).width * _previewPillMaxWidthFactor,
    );

    return desiredWidth.clamp(_previewPillMinWidth, maxWidth);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = colorScheme.primary;
    final Color barColor = isDark
        ? colorScheme.surface.withValues(alpha: 0.88)
        : colorScheme.surface.withValues(alpha: 0.92);
    final Color borderColor = colorScheme.outlineVariant.withValues(
      alpha: isDark ? 0.3 : 0.55,
    );
    final Color textColor = colorScheme.onSurface;
    final Color mutedTextColor = colorScheme.onSurfaceVariant;
    final TextStyle sliderRangeStyle = theme.textTheme.labelSmall!.copyWith(
      color: mutedTextColor.withValues(alpha: 0.8),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    final double bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final _PagePreviewInfo currentInfo = _PagePreviewInfo.fromPage(
      context,
      widget.currentPage,
    );
    final _PagePreviewInfo displayInfo = _isDragging
        ? _PagePreviewInfo.fromPage(context, _previewPage)
        : currentInfo;
    final int displayPage = _isDragging ? _previewPage : widget.currentPage;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double barContentWidth =
            constraints.maxWidth - _barPadding.horizontal;
        final double sliderContentWidth =
            barContentWidth - _sliderSectionPadding.horizontal;
        final double sliderWidth =
            sliderContentWidth -
            (_sliderRangeLabelWidth * 2) -
            (_sliderRangeGap * 2);
        final double sliderInset =
            _barPadding.left +
            _sliderSectionPadding.left +
            _sliderRangeLabelWidth +
            _sliderRangeGap;
        final double pillWidth = _buildPreviewPillWidth(
          context: context,
          surahName: displayInfo.surahName,
          pageNumber: _previewPage,
          availableWidth: constraints.maxWidth - 24,
        );
        final double normalizedValue = (_previewPage - 1) / (_totalPages - 1);
        final double thumbTravelWidth = sliderWidth - _sliderThumbSize;
        final double thumbCenterX =
            sliderInset +
            (_sliderThumbSize / 2) +
            ((1 - normalizedValue) * thumbTravelWidth);
        final double pillLeft = (thumbCenterX - (pillWidth / 2)).clamp(
          0.0,
          constraints.maxWidth - pillWidth,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: _barPadding.left,
                      right: _barPadding.right,
                      top: _barPadding.top,
                      bottom: bottomPadding + _barPadding.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: barColor,
                      border: Border(
                        top: BorderSide(color: borderColor, width: 0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: _sliderSectionPadding,
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(
                              alpha: isDark ? 0.38 : 0.72,
                            ),
                            borderRadius: BorderRadius.circular(
                              _sliderSectionRadius,
                            ),
                            border: Border.all(
                              color: borderColor.withValues(
                                alpha: isDark ? 0.45 : 0.7,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.16 : 0.05,
                                ),
                                blurRadius: 12,
                                spreadRadius: -8,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: _sliderStageHeight,
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: _sliderRangeLabelWidth,
                                        child: Text(
                                          '$_totalPages',
                                          style: sliderRangeStyle,
                                        ),
                                      ),
                                      const SizedBox(width: _sliderRangeGap),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: SizedBox(
                                            height: _sliderHeight,
                                            child: _CustomSlider(
                                              value: _sliderValue,
                                              min: 1,
                                              max: _totalPages.toDouble(),
                                              onChanged: _handleSliderChanged,
                                              onChangeStart:
                                                  _handleSliderChangeStart,
                                              onChangeEnd:
                                                  _handleSliderChangeEnd,
                                              activeColor: primaryColor,
                                              isDark: isDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: _sliderRangeGap),
                                      SizedBox(
                                        width: _sliderRangeLabelWidth,
                                        child: Align(
                                          alignment:
                                              AlignmentDirectional.centerEnd,
                                          child: Text(
                                            '1',
                                            style: sliderRangeStyle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: _NavigationIndexCard(
                                  pageNumber: displayPage,
                                  surahName: displayInfo.surahName,
                                  juzNumber: displayInfo.juzNumber,
                                  hizbLabel: displayInfo.hizbLabel,
                                  primaryColor: primaryColor,
                                  textColor: textColor,
                                  mutedTextColor: mutedTextColor,
                                  surfaceColor: colorScheme.surface,
                                  outlineColor: borderColor,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    widget.onShowIndex();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              _NavigationActionButton(
                                size: _headerActionSize,
                                icon: Icons.share_rounded,
                                backgroundColor: primaryColor.withValues(
                                  alpha: isDark ? 0.16 : 0.1,
                                ),
                                foregroundColor: primaryColor,
                                borderColor: primaryColor.withValues(
                                  alpha: isDark ? 0.18 : 0.12,
                                ),
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).shareButtonLabel,
                                onTap: widget.onShare,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_showPreviewPill)
              Positioned(
                top: -_previewPillTopOffset,
                left: pillLeft,
                child: IgnorePointer(
                  child: _SliderPreviewPill(
                    width: pillWidth,
                    surahName: displayInfo.surahName,
                    pageNumber: _previewPage,
                    primaryColor: primaryColor,
                    backgroundColor: colorScheme.surface,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    isDark: isDark,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SliderPreviewPill extends StatelessWidget {
  const _SliderPreviewPill({
    required this.width,
    required this.surahName,
    required this.pageNumber,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.isDark,
  });

  final double width;
  final String surahName;
  final int pageNumber;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color mutedTextColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color pillBg = backgroundColor;
    final Color pillBorder = primaryColor.withValues(
      alpha: isDark ? 0.34 : 0.2,
    );

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: pillBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.12),
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                surahName,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${context.l10n.page} $pageNumber',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationIndexCard extends StatelessWidget {
  const _NavigationIndexCard({
    required this.pageNumber,
    required this.surahName,
    required this.juzNumber,
    required this.hizbLabel,
    required this.primaryColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.surfaceColor,
    required this.outlineColor,
    required this.isDark,
    required this.onTap,
  });

  final int pageNumber;
  final String surahName;
  final int juzNumber;
  final String hizbLabel;
  final Color primaryColor;
  final Color textColor;
  final Color mutedTextColor;
  final Color surfaceColor;
  final Color outlineColor;
  final bool isDark;
  final VoidCallback onTap;

  String _buildContextSummary(BuildContext context) {
    final StringBuffer buffer = StringBuffer()
      ..write('${context.l10n.page} $pageNumber')
      ..write(' • ${context.l10n.juzPart} $juzNumber');

    if (hizbLabel.isNotEmpty) {
      buffer.write(' • $hizbLabel');
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color cardColor = surfaceColor.withValues(alpha: isDark ? 0.4 : 0.7);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: outlineColor.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                spreadRadius: -7,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  ),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.l10n.surahIndex,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              surahName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: mutedTextColor,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildContextSummary(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationActionButton extends StatelessWidget {
  const _NavigationActionButton({
    required this.size,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.tooltip,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, size: 20, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}

class _CustomSlider extends StatelessWidget {
  const _CustomSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.activeColor,
    required this.isDark,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;
  final Color activeColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final double trackHeight = 6;
    final double thumbSize = _PageNavigationBarState._sliderThumbSize;
    final double thumbRadius = thumbSize / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double normalizedValue = (value - min) / (max - min);
        double interactionValue = value;
        final double trackWidth = (width - thumbSize).clamp(0.0, width);
        // Slider is RTL in Mushaf view: 1 is on the right, 604 on the left.
        final double thumbLeft = (1 - normalizedValue) * trackWidth;
        final double activeTrackWidth = trackWidth - thumbLeft;

        return GestureDetector(
          onHorizontalDragStart: (details) {
            interactionValue = _getValueFromPos(
              details.localPosition.dx,
              width,
            );
            onChangeStart(interactionValue);
          },
          onHorizontalDragUpdate: (details) {
            interactionValue = _getValueFromPos(
              details.localPosition.dx,
              width,
            );
            onChanged(interactionValue);
          },
          onHorizontalDragEnd: (details) {
            onChangeEnd(interactionValue);
          },
          onTapDown: (details) {
            interactionValue = _getValueFromPos(
              details.localPosition.dx,
              width,
            );
            onChangeStart(interactionValue);
            onChanged(interactionValue);
            onChangeEnd(interactionValue);
          },
          child: Container(
            height: 36,
            width: double.infinity,
            color: Colors.transparent, // Hit test area
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Track
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: thumbRadius),
                  child: Container(
                    height: trackHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),
                // Active Track (drawn RTL)
                Positioned(
                  right: thumbRadius,
                  child: Container(
                    height: trackHeight,
                    width: activeTrackWidth,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),
                // Thumb
                Positioned(
                  left: thumbLeft,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.black : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _getValueFromPos(double x, double width) {
    // RTL logic: x=0 is max, x=width is min
    final double normalized = (1 - (x / width)).clamp(0.0, 1.0);
    return min + (normalized * (max - min));
  }
}
