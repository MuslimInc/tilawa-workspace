import 'package:injectable/injectable.dart';
import 'package:quran_qcf/quran_qcf.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/quran_reader_repository.dart';
import '../datasources/datasources.dart';

@LazySingleton(as: QuranReaderRepository)
class QuranReaderRepositoryImpl implements QuranReaderRepository {
  QuranReaderRepositoryImpl(
    this._quranDataSource,
    this._settingsDataSource,
    this._translationDataSource,
  );

  final QuranDataSource _quranDataSource;
  final ReaderSettingsDataSource _settingsDataSource;
  final QuranTranslationDataSource _translationDataSource;

  // In-memory cache for pages to offload logic from the Bloc
  final Map<int, QuranPageEntity> _pageCache = {};
  static const int _maxCachedPages = 20;

  @override
  Future<SurahContentEntity> getSurahContent(int surahNumber) async {
    final SurahContentEntity surah = await _quranDataSource.getSurahContent(
      surahNumber,
    );
    return _attachTranslations(
      surah: surah,
      language: (await _settingsDataSource.loadSettings()).translationLanguage,
    );
  }

  @override
  Future<AyahEntity?> getAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final AyahEntity? ayah = await _quranDataSource.getAyah(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    if (ayah == null) {
      return null;
    }
    final String language =
        (await _settingsDataSource.loadSettings()).translationLanguage;
    final String? translation = await _translationDataSource.getTranslation(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      language: language,
    );
    if (translation == null) {
      return ayah;
    }
    return ayah.copyWith(translation: translation);
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
  }) {
    return _translationDataSource.getTranslation(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      language: language,
    );
  }

  @override
  Future<Map<int, String>> getSurahTranslations({
    required int surahNumber,
    required String language,
  }) {
    return _translationDataSource.getSurahTranslations(
      surahNumber: surahNumber,
      language: language,
    );
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

  Future<SurahContentEntity> _attachTranslations({
    required SurahContentEntity surah,
    required String language,
  }) async {
    final Map<int, String> translations =
        await _translationDataSource.getSurahTranslations(
      surahNumber: surah.number,
      language: language,
    );
    if (translations.isEmpty) {
      return surah;
    }
    return surah.copyWith(
      ayahs: surah.ayahs
          .map((AyahEntity ayah) {
            final String? translation = translations[ayah.numberInSurah];
            if (translation == null) {
              return ayah;
            }
            return ayah.copyWith(translation: translation);
          })
          .toList(growable: false),
    );
  }
}
