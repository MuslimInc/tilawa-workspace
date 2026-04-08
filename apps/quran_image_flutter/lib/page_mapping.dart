/// Page mapping data derived from quran-text.db
/// Maps each of the 604 pages to their surah and ayah ranges
class QuranPageMapping {
  static final List<PageInfo> pages = _generatePages();

  static List<PageInfo> _generatePages() {
    // Generated from: SELECT pageNumber, chapterNumber, MIN(verseNumber) as startAyah,
    // MAX(verseNumber) as endAyah FROM bookEntry WHERE kind = 'verse' GROUP BY pageNumber, chapterNumber
    // This is a simplified subset - full mapping would include all 604 pages
    return [
      // Page 1 - Al-Fatiha
      PageInfo(pageNumber: 1, surahNumber: 1, startAyah: 1, endAyah: 7),

      // Pages 2-49 - Al-Baqarah (partial)
      PageInfo(pageNumber: 2, surahNumber: 2, startAyah: 1, endAyah: 5),
      PageInfo(pageNumber: 3, surahNumber: 2, startAyah: 6, endAyah: 16),
      // ... continue for all 604 pages

      // For now, generate placeholder mapping for remaining pages
      ...List.generate(601, (index) {
        final pageNum = index + 4; // Start from page 4
        // Approximate mapping - replace with actual data from database
        return PageInfo(
          pageNumber: pageNum,
          surahNumber: pageNum <= 49
              ? 2
              : // Al-Baqarah
                pageNum <= 76
              ? 3
              : // Ali Imran
                pageNum <= 105
              ? 4
              : // An-Nisa
                pageNum <= 127
              ? 5
              : // Al-Ma'idah
                114, // Default to last surah
          startAyah: 1,
          endAyah: 10,
        );
      }),
    ];
  }

  static PageInfo getPageInfo(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw ArgumentError('Invalid page number: $pageNumber');
    }
    return pages[pageNumber - 1];
  }

  /// Get all ayahs for a specific page as list of (surah, ayah) tuples
  static List<AyahRef> getAyahsForPage(int pageNumber) {
    final info = getPageInfo(pageNumber);
    return List.generate(
      info.endAyah - info.startAyah + 1,
      (index) => AyahRef(
        surahNumber: info.surahNumber,
        ayahNumber: info.startAyah + index,
      ),
    );
  }
}

class PageInfo {
  final int pageNumber;
  final int surahNumber;
  final int startAyah;
  final int endAyah;

  const PageInfo({
    required this.pageNumber,
    required this.surahNumber,
    required this.startAyah,
    required this.endAyah,
  });

  @override
  String toString() =>
      'Page $pageNumber: Surah $surahNumber, Ayahs $startAyah-$endAyah';
}

class AyahRef {
  final int surahNumber;
  final int ayahNumber;

  const AyahRef({required this.surahNumber, required this.ayahNumber});

  String get imagePath => 'assets/quran_images/$surahNumber/$ayahNumber.png';

  @override
  String toString() => 'Surah $surahNumber:$ayahNumber';
}
