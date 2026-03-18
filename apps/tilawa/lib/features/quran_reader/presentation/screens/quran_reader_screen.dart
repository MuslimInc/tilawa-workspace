import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_index_sheet.dart';

import '../../../../core/presentation/cubit/ui_visibility_cubit.dart';
import '../../../../shared/widgets/bottom_player_widget.dart';
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

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late PageController _pageController;
  int _currentPageNumber = 1;

  @override
  void initState() {
    super.initState();
    // Enable landscape and portrait for this screen only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Ensure UI is visible when entering the reader
    context.read<UiVisibilityCubit>().show();

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

    _currentPageNumber = initialPage;
    _pageController = PageController(initialPage: initialPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Revert to portrait only when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Ensure UI is visible when leaving the reader
    if (mounted) {
      context.read<UiVisibilityCubit>().show();
    }
    super.dispose();
  }

  bool _isInitialPageJumpDone = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuranReaderBloc, QuranReaderState>(
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
          setState(() {
            _isInitialPageJumpDone = true;
          });
        }
      },
      child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.errorMessage != current.errorMessage,
        builder: (context, state) {
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
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(state.errorMessage),
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
                body: GestureDetector(
                  onTap: () {
                    context.read<UiVisibilityCubit>().toggle();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: BlocBuilder<UiVisibilityCubit, bool>(
                    builder: (context, isVisible) {
                      return BlocBuilder<QuranReaderBloc, QuranReaderState>(
                        buildWhen: (oldState, newState) {
                          return oldState.settings != newState.settings ||
                              oldState.status != newState.status;
                        },
                        builder: (context, state) {
                          return QuranPageView(
                            controller: _pageController,
                            onPageChanged: (pageNumber) {
                              setState(() {
                                _currentPageNumber = pageNumber;
                              });
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
                      );
                    },
                  ),
                ),
              ),
              // Page navigation slider — appears when UI chrome is visible
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BlocBuilder<UiVisibilityCubit, bool>(
                  builder: (context, isVisible) {
                    return AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      offset: isVisible ? Offset.zero : const Offset(0, 1),
                      child: _PageNavigationBar(
                        currentPage: _currentPageNumber,
                        onPageChanged: _jumpToPage,
                        onShowIndex: () => _showSurahIndex(context),
                      ),
                    );
                  },
                ),
              ),
              const Positioned.fill(child: BottomPlayerWidget()),
            ],
          );
        },
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
      QuranReaderEvent.saveLastRead(surahNumber: surahNumber, page: pageNumber),
    );
  }
}

/// A bottom bar with a slider for quick page navigation and a surah index button.
class _PageNavigationBar extends StatelessWidget {
  const _PageNavigationBar({
    required this.currentPage,
    required this.onPageChanged,
    required this.onShowIndex,
  });

  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onShowIndex;

  @override
  Widget build(BuildContext context) {
    const totalPages = 604;
    const primaryColor = Color(0xFF4E342E);
    const accentColor = Color(0xFFA68B67);

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    // Determine surah name(s) for the current page
    final pageData = getPageData(currentPage);
    final isArabic = context.l10n.localeName == 'ar';
    final uniqueSurahNumbers = pageData.map((e) => e['surah']!).toSet();
    final surahName = uniqueSurahNumbers
        .map((s) => isArabic ? getSurahNameArabic(s) : getSurahNameEnglish(s))
        .join(' · ');
    final juzNumber = getJuzNumber(
      pageData.first['surah']!,
      pageData.first['start']!,
    );

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 12.h,
            bottom: bottomPadding + 8.h,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F5EF).withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(color: Color(0x1A4E342E), width: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Surah name + page info row
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    // Surah index button
                    GestureDetector(
                      onTap: onShowIndex,
                      child: Container(
                        width: 36.h,
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 18.sp,
                          color: accentColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Surah name
                    Expanded(
                      child: Text(
                        surahName,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Juz + page number
                    Text(
                      '${context.l10n.juzPart} $juzNumber',
                      style: TextStyle(
                        color: primaryColor.withValues(alpha: 0.5),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '$currentPage',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Page slider (RTL: page 1 on the right, 604 on the left)
              SizedBox(
                height: 32.h,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: accentColor,
                      inactiveTrackColor: accentColor.withValues(alpha: 0.15),
                      thumbColor: accentColor,
                      overlayColor: accentColor.withValues(alpha: 0.12),
                      trackHeight: 3.h,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 7.r,
                      ),
                      overlayShape: RoundSliderOverlayShape(
                        overlayRadius: 16.r,
                      ),
                    ),
                    child: Slider(
                      value: currentPage.toDouble(),
                      min: 1,
                      max: totalPages.toDouble(),
                      onChanged: (value) {
                        final page = value.round();
                        if (page != currentPage) {
                          HapticFeedback.selectionClick();
                          onPageChanged(page);
                        }
                      },
                    ),
                  ),
                ),
              ),
              // Page range labels (RTL: 604 on the left, 1 on the right)
              _PageRange(totalPages: totalPages),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageRange extends StatelessWidget {
  const _PageRange({required this.totalPages});

  final int totalPages;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4E342E);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$totalPages',
              style: TextStyle(
                color: primaryColor.withValues(alpha: 0.35),
                fontSize: 10.sp,
              ),
            ),
            Text(
              '1',
              style: TextStyle(
                color: primaryColor.withValues(alpha: 0.35),
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
