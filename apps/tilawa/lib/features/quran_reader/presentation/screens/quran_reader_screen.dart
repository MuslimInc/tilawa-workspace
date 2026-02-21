import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';

import '../bloc/quran_reader_bloc.dart';
import '../widgets/surah_index_sheet.dart';

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
    int initialPage = 1;

    if (widget.surahNumber > 0) {
      initialPage = getPageNumber(widget.surahNumber, 1);
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
    super.dispose();
  }

  bool _isInitialPageJumpDone = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuranReaderBloc, QuranReaderState>(
      listenWhen: (previous, current) =>
          previous.currentPage != current.currentPage &&
          !_isInitialPageJumpDone &&
          widget.surahNumber == 0,
      listener: (context, state) {
        if (state.currentPage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(state.currentPage!.pageNumber - 1);
            }
          });
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

          return Scaffold(
            body: QuranPageView(
              controller: _pageController,
              onPageChanged: (pageNumber) {
                final surahNumber = getPageData(pageNumber).first['surah']!;
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
            ),
            floatingActionButton: _SurahIndexFab(onSurahSelected: _jumpToSurah),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.startFloat,
          );
        },
      ),
    );
  }

  /// Navigates the [PageView] to the first page of [surahNumber].
  void _jumpToSurah(int surahNumber) {
    final int pageNumber = getPageNumber(surahNumber, 1);
    _pageController.jumpToPage(pageNumber - 1);
  }
}

/// A floating action button that opens the surah index sheet.
class _SurahIndexFab extends StatelessWidget {
  const _SurahIndexFab({required this.onSurahSelected});

  final ValueChanged<int> onSurahSelected;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFA68B67);

    return FloatingActionButton.small(
      onPressed: () => _showSurahIndex(context),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tooltip: context.l10n.surahIndex,
      child: const Icon(Icons.menu_book_rounded, size: 20),
    );
  }

  void _showSurahIndex(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SurahIndexSheet(
        onSurahSelected: (surahNumber) {
          Navigator.of(context).pop();
          onSurahSelected(surahNumber);
        },
      ),
    );
  }
}
