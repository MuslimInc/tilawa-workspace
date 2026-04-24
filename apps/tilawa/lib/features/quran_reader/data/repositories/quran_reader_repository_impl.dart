import 'package:injectable/injectable.dart';
import 'package:quran_qcf/quran_qcf.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/quran_reader_repository.dart';
import '../datasources/datasources.dart';

@LazySingleton(as: QuranReaderRepository)
class QuranReaderRepositoryImpl implements QuranReaderRepository {
  QuranReaderRepositoryImpl(this._quranDataSource, this._settingsDataSource);

  final QuranDataSource _quranDataSource;
  final ReaderSettingsDataSource _settingsDataSource;

  // In-memory cache for pages to offload logic from the Bloc
  final Map<int, QuranPageEntity> _pageCache = {};
  static const int _maxCachedPages = 20;

  @override
  Future<SurahContentEntity> getSurahContent(int surahNumber) async {
    return _quranDataSource.getSurahContent(surahNumber);
  }

  @override
  Future<AyahEntity?> getAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return _quranDataSource.getAyah(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
  }

  @override
  Future<QuranPageEntity> getPage(int pageNumber) async {
    // Return from cache if available
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

    final page = await _quranDataSource.getPage(pageNumber);

    // Manage cache size
    if (_pageCache.length >= _maxCachedPages) {
      // Remove the furthest page from the current one to optimize for linear reading
      final keysToRemove = _pageCache.keys.toList()
        ..sort(
          (a, b) => (a - pageNumber).abs().compareTo((b - pageNumber).abs()),
        );

      while (_pageCache.length >= _maxCachedPages) {
        _pageCache.remove(keysToRemove.removeLast());
      }
    }

    _pageCache[pageNumber] = page;
    return page;
  }

  @override
  Future<List<AyahEntity>> getJuz(int juzNumber) async {
    return _quranDataSource.getJuz(juzNumber);
  }

  @override
  Future<List<AyahEntity>> searchAyahs(String query) async {
    return _quranDataSource.searchAyahs(query);
  }

  @override
  Future<String?> getTranslation({
    required int surahNumber,
    required int ayahNumber,
    required String language,
  }) async {
    return null;
  }

  @override
  Future<Map<int, String>> getSurahTranslations({
    required int surahNumber,
    required String language,
  }) async {
    return {};
  }

  @override
  Future<void> saveSettings(ReaderSettingsEntity settings) async {
    await _settingsDataSource.saveSettings(settings);
  }

  @override
  Future<ReaderSettingsEntity> loadSettings() async {
    return _settingsDataSource.loadSettings();
  }

  @override
  Future<void> saveLastReadPosition({
    required int surahNumber,
    int? ayahNumber,
    int? page,
  }) async {
    await _settingsDataSource.saveLastReadPosition(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      page: page,
    );
  }

  @override
  Future<({int? surahNumber, int? ayahNumber, int? page})>
  getLastReadPosition() async {
    return _settingsDataSource.getLastReadPosition();
  }

  @override
  int getStartPageForSurah(int surahNumber) {
    return getPageNumber(surahNumber, 1);
  }
}
