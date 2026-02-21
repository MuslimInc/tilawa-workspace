import 'package:flutter/material.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';

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
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QuranPageView(
        controller: _pageController,
        juzLabel: context.l10n.juzPart,
        hizbLabel: context.l10n.hizb,
        surahNameBuilder: (surahNumber) {
          return context.l10n.localeName == 'ar'
              ? getSurahNameArabic(surahNumber)
              : getSurahNameEnglish(surahNumber);
        },
      ),
      floatingActionButton: _SurahIndexFab(onSurahSelected: _jumpToSurah),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
