import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_index_sheet.dart';

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
<<<<<<< HEAD
  late PageController _pageController;
  late final ValueNotifier<int> _currentPageNotifier;
  late final UiVisibilityCubit _uiVisibilityCubit;
  bool _didInitDependencies = false;
  bool _isInitialPageJumpDone = false;
  final GlobalKey _pageViewKey = GlobalKey();

  static const _headerFontSizeMultiplier = 0.57;
=======
  static const Color _readerSystemBarColor = Color(0xFFF9F5EF);

  late PageController _pageController;
  late final UiVisibilityCubit _uiVisibilityCubit;
  int _currentPageNumber = 1;
>>>>>>> master

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
    _enterReaderImmersiveMode();

    _uiVisibilityCubit = context.read<UiVisibilityCubit>();

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
<<<<<<< HEAD
    final readerTheme = QuranReaderTheme.of(context);
=======
>>>>>>> master
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.top],
    );
    SystemChrome.setSystemUIOverlayStyle(
<<<<<<< HEAD
      SystemUiOverlayStyle(
        statusBarColor: readerTheme.systemBarColor,
        statusBarIconBrightness: readerTheme.statusBarIconBrightness,
        statusBarBrightness: readerTheme.statusBarBrightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: readerTheme.statusBarIconBrightness,
=======
      const SystemUiOverlayStyle(
        statusBarColor: _readerSystemBarColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
>>>>>>> master
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  void _restoreAppSystemUiMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle());
  }
<<<<<<< HEAD

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
=======

  bool _isInitialPageJumpDone = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return BlocListener<QuranReaderBloc, QuranReaderState>(
      listenWhen: (previous, current) =>
          previous.currentPage != current.currentPage &&
          current.currentPage != null,
      listener: (context, state) {
        final pageNumber = state.currentPage!.pageNumber;
>>>>>>> master

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

<<<<<<< HEAD
          if (!_isInitialPageJumpDone) {
            if (mounted) {
              setState(() {
                _isInitialPageJumpDone = true;
              });
            }
=======
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
>>>>>>> master
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
                        return QuranPageView(
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

  void _showSurahIndex(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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

    final int? quarterNumber =
        pageNumber == 1 || pageNumber == 2
            ? null
            : getQuarterNumber(
              pageData.first['surah']!,
              pageData.first['start']!,
            );

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
      surahName:
          uniqueSurahNumbers
              .map(
                (surahNumber) =>
                    isArabic
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
  });

  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onShowIndex;

  @override
  State<_PageNavigationBar> createState() => _PageNavigationBarState();
}

class _PageNavigationBarState extends State<_PageNavigationBar> {
  static const int _totalPages = 604;
  static const double _sliderHeight = 32;
<<<<<<< HEAD
  static const double _sliderPreviewHeight = 140;
  static const double _sliderThumbRadius = 8;
  static const double _sliderOverlayRadius = 24;
  static const Duration _animationDuration = Duration(milliseconds: 200);
=======
  static const double _sliderPreviewHeight = 76;
  static const double _sliderThumbRadius = 7;
  static const double _sliderOverlayRadius = 16;
  static const Duration _animationDuration = Duration(milliseconds: 180);
>>>>>>> master

  double? _sliderValueOverride;
  int? _lastPreviewPage;
  bool _showPreviewPill = false;

  bool get _isDragging => _showPreviewPill;

  double get _sliderValue =>
      _sliderValueOverride ?? widget.currentPage.toDouble();

  int get _previewPage => _sliderValue.round().clamp(1, _totalPages);

  @override
  void didUpdateWidget(covariant _PageNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_showPreviewPill &&
        _sliderValueOverride != null &&
        widget.currentPage != oldWidget.currentPage) {
      setState(() {
        _sliderValueOverride = null;
      });
    }
  }

  void _handleSliderChangeStart(double value) {
    setState(() {
      _showPreviewPill = true;
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
      _showPreviewPill = false;
      _sliderValueOverride = shouldNavigate ? targetPage.toDouble() : null;
      _lastPreviewPage = null;
    });

    if (shouldNavigate) {
      widget.onPageChanged(targetPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
<<<<<<< HEAD
    final bool isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = colorScheme.primary;
    final Color barColor = isDark
        ? colorScheme.surface.withValues(alpha: 0.88)
        : colorScheme.surface.withValues(alpha: 0.92);
    final Color borderColor = colorScheme.outlineVariant.withValues(
      alpha: isDark ? 0.3 : 0.55,
=======
    final Color primaryColor = colorScheme.primary;
    final Color accentColor = colorScheme.primary;
    final Color barColor = colorScheme.surface.withValues(alpha: 0.92);
    final Color borderColor = colorScheme.outlineVariant.withValues(
      alpha: 0.55,
>>>>>>> master
    );
    final Color textColor = colorScheme.onSurface;
    final Color mutedTextColor = colorScheme.onSurfaceVariant;
    final double bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final _PagePreviewInfo currentInfo = _PagePreviewInfo.fromPage(
      context,
      widget.currentPage,
    );
    final _PagePreviewInfo previewInfo = _isDragging
        ? _PagePreviewInfo.fromPage(context, _previewPage)
        : currentInfo;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
<<<<<<< HEAD
              top: 16,
=======
              top: 12,
>>>>>>> master
              bottom: bottomPadding + 8,
            ),
            decoration: BoxDecoration(
              color: barColor,
              border: Border(top: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info row
                Padding(
<<<<<<< HEAD
                  padding: const EdgeInsets.only(bottom: 12),
=======
                  padding: EdgeInsets.only(bottom: 8),
>>>>>>> master
                  child: Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
<<<<<<< HEAD
                      Row(
                        children: [
                          // Page number badge
                          Container(
                            constraints: const BoxConstraints(minWidth: 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(
                                alpha: isDark ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${widget.currentPage}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Juz + Hizb info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${context.l10n.juzPart} ${currentInfo.juzNumber}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (currentInfo.hizbLabel.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  currentInfo.hizbLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: mutedTextColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
=======
                      // Surah index button
                      GestureDetector(
                        onTap: widget.onShowIndex,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: primaryColor,
>>>>>>> master
                          ),
                        ],
                      ),
<<<<<<< HEAD
                      Expanded(
                        child: Row(
                          mainAxisAlignment: .end,
                          children: [
                            // Surah names
                            Flexible(
                              flex: 3,
                              child: Text(
                                currentInfo.surahName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Surah index button
                            Material(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              elevation: isDark ? 0 : 2,
                              shadowColor: primaryColor.withValues(alpha: 0.3),
                              child: InkWell(
                                onTap: widget.onShowIndex,
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.menu_book_rounded,
                                    size: 20,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
=======
                      SizedBox(width: 10),
                      // Surah name
                      Expanded(
                        child: Text(
                          currentInfo.surahName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Juz + Hizb info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${context.l10n.juzPart} ${currentInfo.juzNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (currentInfo.hizbLabel.isNotEmpty)
                            Text(
                              currentInfo.hizbLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: mutedTextColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.currentPage}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
>>>>>>> master
                        ),
                      ),
                    ],
                  ),
                ),
<<<<<<< HEAD
                // Page slider
=======
                // Page slider (RTL: page 1 on the right, 604 on the left)
>>>>>>> master
                AnimatedContainer(
                  duration: _animationDuration,
                  curve: Curves.easeOutCubic,
                  height: _isDragging ? _sliderPreviewHeight : _sliderHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double pillWidth = (constraints.maxWidth * 0.48)
                          .clamp(160.0, 220.0);
                      final double trackInset =
                          _sliderOverlayRadius > _sliderThumbRadius
                          ? _sliderOverlayRadius
                          : _sliderThumbRadius;
                      final double usableTrackWidth =
                          (constraints.maxWidth - (trackInset * 2)).clamp(
                            0.0,
                            constraints.maxWidth,
                          );
                      final double normalizedValue =
                          (_previewPage - 1) / (_totalPages - 1);
                      final double thumbCenterX =
                          trackInset +
                          ((1 - normalizedValue) * usableTrackWidth);
                      final double pillLeft = (thumbCenterX - (pillWidth / 2))
                          .clamp(0.0, constraints.maxWidth - pillWidth);

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
<<<<<<< HEAD
                            bottom: 12,
                            child: _CustomSlider(
                              value: _sliderValue,
                              min: 1,
                              max: _totalPages.toDouble(),
                              onChanged: _handleSliderChanged,
                              onChangeStart: _handleSliderChangeStart,
                              onChangeEnd: _handleSliderChangeEnd,
                              activeColor: primaryColor,
                              isDark: isDark,
=======
                            bottom: 0,
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: accentColor,
                                  inactiveTrackColor: accentColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  thumbColor: accentColor,
                                  overlayColor: accentColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  trackHeight: 3,
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: _sliderThumbRadius,
                                  ),
                                  overlayShape: RoundSliderOverlayShape(
                                    overlayRadius: _sliderOverlayRadius,
                                  ),
                                ),
                                child: Slider(
                                  value: _sliderValue,
                                  min: 1,
                                  max: _totalPages.toDouble(),
                                  onChangeStart: _handleSliderChangeStart,
                                  onChanged: _handleSliderChanged,
                                  onChangeEnd: _handleSliderChangeEnd,
                                ),
                              ),
>>>>>>> master
                            ),
                          ),
                          if (_isDragging)
                            Positioned(
                              top: 0,
                              left: pillLeft,
                              child: IgnorePointer(
                                child: _SliderPreviewPill(
                                  width: pillWidth,
                                  surahName: previewInfo.surahName,
                                  pageNumber: _previewPage,
                                  primaryColor: primaryColor,
                                  backgroundColor: colorScheme.surface,
                                  textColor: textColor,
                                  mutedTextColor: mutedTextColor,
<<<<<<< HEAD
                                  isDark: isDark,
=======
>>>>>>> master
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
<<<<<<< HEAD
                // Page range labels
=======
                // Page range labels (RTL: 604 on the left, 1 on the right)
>>>>>>> master
                const _PageRange(totalPages: _totalPages),
              ],
            ),
          ),
        ),
      ),
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
<<<<<<< HEAD
    required this.isDark,
=======
>>>>>>> master
  });

  final double width;
  final String surahName;
  final int pageNumber;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color mutedTextColor;
<<<<<<< HEAD
  final bool isDark;
=======
>>>>>>> master

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
<<<<<<< HEAD
    final Color pillBg = backgroundColor.withValues(
      alpha: isDark ? 0.92 : 0.85,
    );
    final Color pillBorder = primaryColor.withValues(
      alpha: isDark ? 0.25 : 0.15,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: pillBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    surahName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${context.l10n.page} $pageNumber',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Pointer triangle
        CustomPaint(
          size: const Size(12, 6),
          painter: _TrianglePainter(color: pillBg, borderColor: pillBorder),
        ),
      ],
=======

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            surahName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${context.l10n.page} $pageNumber',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: mutedTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
>>>>>>> master
    );
  }
}

<<<<<<< HEAD
class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

=======
>>>>>>> master
class _PageRange extends StatelessWidget {
  const _PageRange({required this.totalPages});

  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final Color rangeColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$totalPages',
              style: TextStyle(color: rangeColor, fontSize: 10),
            ),
            Text('1', style: TextStyle(color: rangeColor, fontSize: 10)),
          ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double normalizedValue = (value - min) / (max - min);
        // Slider is RTL in Mushaf view: 1 is on the right, 604 on the left.
        final double thumbPos = (1 - normalizedValue) * width;

        return GestureDetector(
          onHorizontalDragStart: (details) {
            onChangeStart(_getValueFromPos(details.localPosition.dx, width));
          },
          onHorizontalDragUpdate: (details) {
            onChanged(_getValueFromPos(details.localPosition.dx, width));
          },
          onHorizontalDragEnd: (details) {
            onChangeEnd(value);
          },
          onTapDown: (details) {
            onChangeStart(_getValueFromPos(details.localPosition.dx, width));
            onChanged(_getValueFromPos(details.localPosition.dx, width));
            onChangeEnd(value);
          },
          child: Container(
            height: 32,
            width: double.infinity,
            color: Colors.transparent, // Hit test area
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Track
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Active Track (drawn RTL)
                Positioned(
                  right: 0,
                  child: Container(
                    height: 4,
                    width: width - thumbPos,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Thumb
                Positioned(
                  left: thumbPos - 7,
                  child: Container(
                    width: 14,
                    height: 14,
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
                          blurRadius: 4,
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
