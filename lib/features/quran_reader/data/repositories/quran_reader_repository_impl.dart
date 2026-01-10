import 'package:injectable/injectable.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/quran_reader_repository.dart';
import '../datasources/datasources.dart';

@LazySingleton(as: QuranReaderRepository)
class QuranReaderRepositoryImpl implements QuranReaderRepository {
  QuranReaderRepositoryImpl(
    this._quranDataSource,
    this._readerSettingsDataSource,
    this._searchRemoteDataSource,
  );

  final QuranDataSource _quranDataSource;
  final ReaderSettingsDataSource _readerSettingsDataSource;
  final SearchRemoteDataSource _searchRemoteDataSource;

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
    return _quranDataSource.getPage(pageNumber);
  }

  @override
  Future<Map<int, QuranPageEntity>> getAllPages() async {
    return _quranDataSource.getAllPages();
  }

  @override
  Future<List<AyahEntity>> getJuz(int juzNumber) async {
    return _quranDataSource.getJuz(juzNumber);
  }

  @override
  Future<List<AyahEntity>> searchAyahs(String query) async {
    // 1. Try remote search
    final List<RemoteSearchResult> remoteResults = await _searchRemoteDataSource
        .search(query);

    if (remoteResults.isNotEmpty) {
      final List<AyahEntity> results = [];
      for (final remote in remoteResults) {
        final List<String> parts = remote.verseKey.split(':');
        if (parts.length == 2) {
          final int? surahNum = int.tryParse(parts[0]);
          final int? ayahNum = int.tryParse(parts[1]);
          if (surahNum != null && ayahNum != null) {
            final AyahEntity? ayah = await _quranDataSource.getAyah(
              surahNumber: surahNum,
              ayahNumber: ayahNum,
            );
            if (ayah != null) {
              // Attach the translation snippet if available, stripping HTML tags
              final String? snippet = remote.translation?.replaceAll(
                RegExp(r'<[^>]*>'),
                '',
              );
              results.add(ayah.copyWith(translation: snippet));
            }
          }
        }
      }
      if (results.isNotEmpty) {
        return results;
      }
    }

    // 2. Fallback to local search
    return _quranDataSource.searchAyahs(query);
  }

  @override
  Future<List<SurahContentEntity>> searchSurahs(String query) async {
    return _quranDataSource.searchSurahs(query);
  }

  @override
  Future<String?> getTranslation({
    required int surahNumber,
    required int ayahNumber,
    required String language,
  }) async {
    // This would load translation from a separate data source
    // For now, return null
    return null;
  }

  @override
  Future<Map<int, String>> getSurahTranslations({
    required int surahNumber,
    required String language,
  }) async {
    // This would load translations from a separate data source
    // For now, return empty map
    return {};
  }

  @override
  Future<void> saveSettings(ReaderSettingsEntity settings) async {
    await _readerSettingsDataSource.saveSettings(settings);
  }

  @override
  Future<ReaderSettingsEntity> loadSettings() async {
    return _readerSettingsDataSource.loadSettings();
  }

  @override
  Future<void> saveLastReadPosition({
    required int surahNumber,
    int? ayahNumber,
    int? page,
  }) async {
    await _readerSettingsDataSource.saveLastReadPosition(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      page: page,
    );
  }

  @override
  Future<({int? surahNumber, int? ayahNumber, int? page})>
  getLastReadPosition() async {
    return _readerSettingsDataSource.getLastReadPosition();
  }

  @override
  int get totalJuz => throw UnimplementedError();

  @override
  int get totalPages => throw UnimplementedError();
}
