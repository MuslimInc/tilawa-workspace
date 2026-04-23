import '../models/quran_models.dart';
import '../models/quran_special_line.dart';

/// Service interface for raw Quran mushaf data operations.
///
/// Provides access to raw word-level data, special lines, and verse metadata.
/// Used primarily by layout and rendering services.
abstract class QuranMushafService {
  /// Whether the Quran data is fully loaded.
  bool get isLoaded;

  /// Ensures Quran data is loaded from assets.
  Future<void> ensureLoaded();

  /// Gets raw page data (word entries with metadata) for a given page number.
  List<List<WordData>>? getPageData(int pageNumber);

  /// Gets the index of the last word in a verse.
  int? getLastWordIndexForVerse(int surahNumber, int verseNumber);

  /// Checks whether the given word data represents the end of a verse.
  bool isVerseEndWord(WordData wordData);

  /// Gets counts of special lines (headers, bismillahs) on a page.
  Map<String, int> getSpecialLineCounts(int pageNumber);

  /// Gets detailed special line information for a page.
  QuranSpecialLineCounts getSpecialLineCountSummary(int pageNumber);

  /// Gets a special line by page and line number.
  QuranSpecialLine? getSpecialLine(int page, int line);

  /// Returns whether a page has a surah header.
  bool pageHasSurahHeader(int pageNumber);

  /// Gets metadata for a specific page.
  PageMetadata getPageMetadata(int pageNumber);
}
