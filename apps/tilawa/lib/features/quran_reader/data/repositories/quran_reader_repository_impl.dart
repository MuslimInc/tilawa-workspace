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
