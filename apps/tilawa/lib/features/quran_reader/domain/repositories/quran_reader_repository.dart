import '../entities/entities.dart';

/// Repository interface for Quran reader operations
abstract class QuranReaderRepository {
  /// Get all ayahs for a specific surah
  Future<SurahContentEntity> getSurahContent(int surahNumber);

  /// Get a specific ayah
  Future<AyahEntity?> getAyah({
    required int surahNumber,
    required int ayahNumber,
  });

  /// Get ayahs for a specific page
  Future<QuranPageEntity> getPage(int pageNumber);

  /// Get ayahs for a specific juz
  Future<List<AyahEntity>> getJuz(int juzNumber);

  /// Search ayahs by text
  Future<List<AyahEntity>> searchAyahs(String query);

  /// Get translation for an ayah
  Future<String?> getTranslation({
    required int surahNumber,
    required int ayahNumber,
    required String language,
  });

  /// Get translations for a surah
  Future<Map<int, String>> getSurahTranslations({
    required int surahNumber,
    required String language,
  });

  /// Save reader settings
  Future<void> saveSettings(ReaderSettingsEntity settings);

  /// Load reader settings
  Future<ReaderSettingsEntity> loadSettings();

  /// Save last read position
  Future<void> saveLastReadPosition({
    required int surahNumber,
    int? ayahNumber,
    int? page,
  });

  /// Get last read position
  Future<({int? surahNumber, int? ayahNumber, int? page})>
  getLastReadPosition();

  /// Get total page count
  int get totalPages => 604;

  /// Get total juz count
  int get totalJuz => 30;
}
