import 'package:injectable/injectable.dart';

import '../../domain/entities/entities.dart';
import 'quran_local_datasource.dart';
import 'quran_remote_datasource.dart';

/// Abstract interface for Quran data operations.
///
/// This interface defines the contract for accessing Quran data,
/// abstracting away the implementation details of local vs remote sources.
abstract class QuranDataSource {
  /// Gets surah content by number.
  Future<SurahContentEntity> getSurahContent(int surahNumber);

  /// Gets a specific ayah.
  Future<AyahEntity?> getAyah({
    required int surahNumber,
    required int ayahNumber,
  });

  /// Gets page data including ayahs and words.
  Future<QuranPageEntity> getPage(int pageNumber);

  /// Gets all pages.
  Future<Map<int, QuranPageEntity>> getAllPages();

  /// Gets all ayahs for a juz.
  Future<List<AyahEntity>> getJuz(int juzNumber);

  /// Searches ayahs by text.
  Future<List<AyahEntity>> searchAyahs(String query);

  /// Searches surahs by name or number.
  Future<List<SurahContentEntity>> searchSurahs(String query);

  /// Gets word-by-word data for a page.
  Future<Map<String, List<QuranWord>>> getPageWords(int pageNumber);
}

/// Implementation of [QuranDataSource] that coordinates between
/// local and remote data sources.
///
/// Follows the Facade pattern to provide a simple interface while
/// delegating to specialized data sources.
@LazySingleton(as: QuranDataSource)
class QuranDataSourceImpl implements QuranDataSource {
  QuranDataSourceImpl(this._localDataSource, this._remoteDataSource);

  final QuranLocalDataSource _localDataSource;
  final QuranRemoteDataSource _remoteDataSource;

  @override
  Future<SurahContentEntity> getSurahContent(int surahNumber) {
    return _localDataSource.getSurahContent(surahNumber);
  }

  @override
  Future<AyahEntity?> getAyah({
    required int surahNumber,
    required int ayahNumber,
  }) {
    return _localDataSource.getAyah(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
  }

  @override
  Future<QuranPageEntity> getPage(int pageNumber) async {
    // First get the page from local source
    final QuranPageEntity page = await _localDataSource.getPage(pageNumber);

    // If words are already loaded, return as-is
    if (page.ayahs.isNotEmpty && page.ayahs.first.words != null) {
      return page;
    }

    // Fetch words from remote and update local cache
    try {
      final Map<String, List<QuranWord>> words = await _remoteDataSource
          .getPageWords(pageNumber);
      if (words.isNotEmpty) {
        await _localDataSource.updatePageWithWords(pageNumber, words);
        return _localDataSource.getPage(pageNumber);
      }
    } catch (e) {
      // Fall back to text-only page if remote fails
    }

    return page;
  }

  @override
  Future<Map<int, QuranPageEntity>> getAllPages() {
    return _localDataSource.getAllPages();
  }

  @override
  Future<List<AyahEntity>> getJuz(int juzNumber) {
    return _localDataSource.getJuz(juzNumber);
  }

  @override
  Future<List<AyahEntity>> searchAyahs(String query) {
    return _localDataSource.searchAyahs(query);
  }

  @override
  Future<List<SurahContentEntity>> searchSurahs(String query) {
    return _localDataSource.searchSurahs(query);
  }

  @override
  Future<Map<String, List<QuranWord>>> getPageWords(int pageNumber) {
    return _remoteDataSource.getPageWords(pageNumber);
  }
}
