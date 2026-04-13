import 'domain/entities/page_state.dart';

/// Page mapping data derived from the Uthmani mushaf layout.
///
/// Maps each of the 604 pages to their surah, juz, and hizb ranges.
/// Surah boundaries are extracted from `quran_page_index.json`.
/// Juz and hizb boundaries use the standard Uthmani mushaf layout.
class QuranPageMapping {
  QuranPageMapping._();

  static final List<PageInfo> pages = List.generate(PageState.quranPageCount, (
    index,
  ) {
    final pageNum = index + 1;
    return PageInfo(
      pageNumber: pageNum,
      juzNumber: _getJuzForPage(pageNum),
      hizbNumber: _getHizbForPage(pageNum),
      surahNumber: _getSurahForPage(pageNum),
    );
  });

  /// Returns the primary surah number for the given page.
  ///
  /// For pages containing multiple surahs, returns the surah whose
  /// content begins first (i.e. the starting surah on that page).
  static int _getSurahForPage(int pageNum) {
    if (pageNum <= 1) return 1;
    if (pageNum <= 49) return 2;
    if (pageNum <= 76) return 3;
    if (pageNum <= 106) return 4;
    if (pageNum <= 127) return 5;
    if (pageNum <= 150) return 6;
    if (pageNum <= 176) return 7;
    if (pageNum <= 186) return 8;
    if (pageNum <= 207) return 9;
    if (pageNum <= 221) return 10;
    if (pageNum <= 235) return 11;
    if (pageNum <= 248) return 12;
    if (pageNum <= 255) return 13;
    if (pageNum <= 261) return 14;
    if (pageNum <= 267) return 15;
    if (pageNum <= 281) return 16;
    if (pageNum <= 293) return 17;
    if (pageNum <= 304) return 18;
    if (pageNum <= 312) return 19;
    if (pageNum <= 321) return 20;
    if (pageNum <= 331) return 21;
    if (pageNum <= 341) return 22;
    if (pageNum <= 349) return 23;
    if (pageNum <= 359) return 24;
    if (pageNum <= 366) return 25;
    if (pageNum <= 376) return 26;
    if (pageNum <= 385) return 27;
    if (pageNum <= 396) return 28;
    if (pageNum <= 404) return 29;
    if (pageNum <= 410) return 30;
    if (pageNum <= 414) return 31;
    if (pageNum <= 417) return 32;
    if (pageNum <= 427) return 33;
    if (pageNum <= 434) return 34;
    if (pageNum <= 440) return 35;
    if (pageNum <= 445) return 36;
    if (pageNum <= 452) return 37;
    if (pageNum <= 458) return 38;
    if (pageNum <= 467) return 39;
    if (pageNum <= 476) return 40;
    if (pageNum <= 482) return 41;
    if (pageNum <= 489) return 42;
    if (pageNum <= 495) return 43;
    if (pageNum <= 498) return 44;
    if (pageNum <= 502) return 45;
    if (pageNum <= 506) return 46;
    if (pageNum <= 510) return 47;
    if (pageNum <= 515) return 48;
    if (pageNum <= 517) return 49;
    if (pageNum <= 520) return 50;
    if (pageNum <= 523) return 51;
    if (pageNum <= 525) return 52;
    if (pageNum <= 528) return 53;
    if (pageNum <= 531) return 54;
    if (pageNum <= 534) return 55;
    if (pageNum <= 537) return 56;
    if (pageNum <= 541) return 57;
    if (pageNum <= 545) return 58;
    if (pageNum <= 548) return 59;
    if (pageNum <= 551) return 60;
    if (pageNum <= 554) return 62;
    if (pageNum <= 557) return 64;
    if (pageNum <= 559) return 65;
    if (pageNum <= 561) return 66;
    if (pageNum <= 564) return 67;
    if (pageNum <= 566) return 68;
    if (pageNum <= 568) return 69;
    if (pageNum <= 570) return 70;
    if (pageNum <= 573) return 72;
    if (pageNum <= 575) return 73;
    if (pageNum <= 577) return 74;
    if (pageNum <= 580) return 76;
    if (pageNum <= 583) return 78;
    if (pageNum <= 586) return 80;
    if (pageNum <= 589) return 83;
    if (pageNum <= 590) return 84;
    if (pageNum <= 591) return 86;
    if (pageNum <= 592) return 87;
    if (pageNum <= 593) return 88;
    if (pageNum <= 594) return 89;
    if (pageNum <= 595) return 90;
    if (pageNum <= 596) return 92;
    if (pageNum <= 597) return 94;
    if (pageNum <= 598) return 96;
    if (pageNum <= 599) return 98;
    if (pageNum <= 600) return 100;
    if (pageNum <= 601) return 103;
    if (pageNum <= 602) return 106;
    if (pageNum <= 603) return 109;
    return 112;
  }

  /// Juz starting pages for the standard Uthmani mushaf.
  static const List<int> _juzStartPages = [
    1,
    22,
    42,
    62,
    82,
    102,
    121,
    142,
    162,
    182,
    201,
    222,
    242,
    262,
    282,
    302,
    322,
    342,
    362,
    382,
    402,
    422,
    442,
    462,
    482,
    502,
    522,
    542,
    562,
    582,
  ];

  /// Returns the juz number (1-30) for the given page.
  static int _getJuzForPage(int pageNum) {
    for (int j = _juzStartPages.length - 1; j >= 0; j--) {
      if (pageNum >= _juzStartPages[j]) return j + 1;
    }
    return 1;
  }

  /// Hizb starting pages for the standard Uthmani mushaf.
  static const List<int> _hizbStartPages = [
    1,
    12,
    22,
    32,
    42,
    52,
    62,
    72,
    82,
    92,
    102,
    112,
    121,
    132,
    142,
    152,
    162,
    173,
    182,
    192,
    201,
    212,
    222,
    232,
    242,
    252,
    262,
    272,
    282,
    292,
    302,
    312,
    322,
    332,
    342,
    352,
    362,
    372,
    382,
    392,
    402,
    413,
    422,
    432,
    442,
    452,
    462,
    472,
    482,
    492,
    502,
    513,
    522,
    532,
    542,
    553,
    562,
    572,
    582,
    591,
  ];

  /// Returns the hizb number (1-60) for the given page.
  static int _getHizbForPage(int pageNum) {
    for (int h = _hizbStartPages.length - 1; h >= 0; h--) {
      if (pageNum >= _hizbStartPages[h]) return h + 1;
    }
    return 1;
  }

  /// Gets the [PageInfo] for a given page number.
  ///
  /// Throws [ArgumentError] if [pageNumber] is out of range.
  static PageInfo getPageInfo(int pageNumber) {
    if (pageNumber < 1 || pageNumber > PageState.quranPageCount) {
      throw ArgumentError('Invalid page number: $pageNumber');
    }
    return pages[pageNumber - 1];
  }
}

/// Immutable metadata for a single Quran page.
class PageInfo {
  final int pageNumber;
  final int surahNumber;
  final int juzNumber;
  final int hizbNumber;

  const PageInfo({
    required this.pageNumber,
    required this.surahNumber,
    required this.juzNumber,
    required this.hizbNumber,
  });

  String get juzTitle => 'Juz $juzNumber';
  String get hizbTitle => 'Hizb $hizbNumber';

  @override
  String toString() => 'Page $pageNumber: Juz $juzNumber, Hizb $hizbNumber';
}
