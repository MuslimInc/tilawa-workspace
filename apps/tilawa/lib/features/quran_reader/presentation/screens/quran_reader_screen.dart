import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      // Trigger load for the specific surah if it's not already loaded or if it's a different surah
      final bloc = context.read<QuranReaderBloc>();
      if (bloc.state.currentSurah?.number != widget.surahNumber) {
        bloc.add(QuranReaderEvent.loadSurah(widget.surahNumber));
      } else {
        // Even if already loaded, ensure saveLastRead is triggered for initial position
        bloc.add(
          QuranReaderEvent.saveLastRead(
            surahNumber: widget.surahNumber,
            page: initialPage,
          ),
        );
      }
    } else {
      // For last read (surahNumber == 0), check if the global bloc already has a page
      final currentState = context.read<QuranReaderBloc>().state;
      if (currentState.currentPage != null) {
        initialPage = currentState.currentPage!.pageNumber;
        _isInitialPageJumpDone = true;
      }
    }

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
        // Use a small epsilon for page comparison
        if (_pageController.hasClients) {
          final currentPageInController = _pageController.page?.round() ?? 0;
          if (currentPageInController + 1 != pageNumber) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
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
                      return QuranPageView(
                        controller: _pageController,
                        onPageChanged: (pageNumber) {
                          // Delegate to bloc - it will handle saving last read and syncing state
                          context.read<QuranReaderBloc>().add(
                            QuranReaderEvent.loadPage(pageNumber),
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
    // Delegate to bloc - it will trigger loadPage which the listener above handles
    context.read<QuranReaderBloc>().add(
      QuranReaderEvent.loadSurah(surahNumber),
    );
  }
}
