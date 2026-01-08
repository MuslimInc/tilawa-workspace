import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/entities.dart';
import '../models/surah_metadata.dart';
import 'arabic_text_utils.dart';

/// Data source for loading Quran data from local assets.
///
/// Handles loading and caching of Quran JSON data from the app bundle.
/// Follows Single Responsibility Principle by only handling local data.
abstract class QuranLocalDataSource {
  /// Loads surah content for a given surah number.
  Future<SurahContentEntity> getSurahContent(int surahNumber);

  /// Gets a specific ayah by surah and ayah number.
  Future<AyahEntity?> getAyah({
    required int surahNumber,
    required int ayahNumber,
  });

  /// Gets all ayahs for a specific page.
  Future<QuranPageEntity> getPage(int pageNumber);

  /// Gets all ayahs for a specific juz.
  Future<List<AyahEntity>> getJuz(int juzNumber);

  /// Searches ayahs by text query.
  Future<List<AyahEntity>> searchAyahs(String query);

  /// Searches surahs by name or number.
  Future<List<SurahContentEntity>> searchSurahs(String query);

  /// Updates page cache with word data.
  void updatePageWithWords(int pageNumber, Map<String, List<QuranWord>> words);
}

@LazySingleton(as: QuranLocalDataSource)
class QuranLocalDataSourceImpl implements QuranLocalDataSource {
  QuranLocalDataSourceImpl({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  Map<String, dynamic>? _quranData;
  List<dynamic>? _surahList;
  final Map<int, QuranPageEntity> _pageCache = {};

  /// Ensures Quran data is loaded from assets.
  Future<void> _ensureDataLoaded() async {
    if (_quranData != null) return;

    try {
      final String jsonString = await _assetBundle.loadString(
        'assets/data/quran.json',
      );

      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;

      if (parsed.containsKey('data') && parsed['data'] is Map) {
        _quranData = parsed;
        _surahList = parsed['data']['surahs'] as List<dynamic>?;
      } else if (parsed.containsKey('surahs')) {
        _quranData = parsed;
        _surahList = parsed['surahs'] as List<dynamic>?;
      } else {
        throw const FormatException('Unexpected Quran data format');
      }

      _preloadPages();
    } catch (e) {
      _quranData = {
        'data': {'surahs': []},
      };
      _surahList = [];
    }
  }

  void _preloadPages() {
    if (_surahList == null || _surahList!.isEmpty) return;

    final Map<int, List<PageAyahInfo>> pageAyahsMap = {};
    final Map<int, int> pageJuzMap = {};
    final Map<int, int> pageHizbMap = {};

    for (final surah in _surahList!) {
      final List<dynamic> surahAyahs = surah['ayahs'] as List<dynamic>? ?? [];
      final String surahName = surah['name'] as String? ?? '';
      final int surahNum = surah['number'] as int? ?? 0;
      final String surahNameEnglish = surah['englishName'] as String? ?? '';

      for (final ayah in surahAyahs) {
        final int page = ayah['page'] as int? ?? 0;
        if (page == 0) continue;

        pageAyahsMap.putIfAbsent(page, () => []);

        if (!pageJuzMap.containsKey(page) && ayah['juz'] != null) {
          pageJuzMap[page] = ayah['juz'] as int;
        }

        if (!pageHizbMap.containsKey(page) && ayah['hizbQuarter'] != null) {
          final hizbQuarter = ayah['hizbQuarter'] as int;
          pageHizbMap[page] = (hizbQuarter / 4).ceil();
        }

        final int ayahNum = ayah['numberInSurah'] as int? ?? 0;

        pageAyahsMap[page]!.add(
          PageAyahInfo(
            surahNumber: surahNum,
            surahName: surahName,
            surahNameEnglish: surahNameEnglish,
            ayahNumber: ayahNum,
            text: ayah['text'] as String? ?? '',
          ),
        );
      }
    }

    for (var i = 1; i <= 604; i++) {
      final List<PageAyahInfo> ayahs = pageAyahsMap[i] ?? [];
      final int juz = pageJuzMap[i] ?? ((i - 1) ~/ 20) + 1;
      final int hizb = pageHizbMap[i] ?? ((i - 1) ~/ 10) + 1;

      _pageCache[i] = QuranPageEntity(
        pageNumber: i,
        ayahs: ayahs,
        juz: juz,
        hizb: hizb,
      );
    }
  }

  @override
  Future<SurahContentEntity> getSurahContent(int surahNumber) async {
    await _ensureDataLoaded();

    if (_surahList == null || _surahList!.isEmpty) {
      return _getMockSurahContent(surahNumber);
    }

    try {
      final dynamic surahData = _surahList?.firstWhereOrNull(
        (s) => s['number'] == surahNumber,
      );

      if (surahData == null) {
        return _getMockSurahContent(surahNumber);
      }

      final List<AyahEntity> ayahs = (surahData['ayahs'] as List<dynamic>)
          .map(
            (a) => AyahEntity(
              number: a['number'] ?? 0,
              numberInSurah: a['numberInSurah'] ?? 0,
              surahNumber: surahNumber,
              text: a['text'] ?? '',
              juz: a['juz'],
              manzil: a['manzil'],
              page: a['page'],
              ruku: a['ruku'],
              hizbQuarter: a['hizbQuarter'],
              sajda: a['sajda'] != null && a['sajda'] != false,
            ),
          )
          .toList();

      final SurahMetadata metadata = SurahMetadataRepository.getSurah(
        surahNumber,
      );

      return SurahContentEntity(
        number: surahNumber,
        name: metadata.nameArabic,
        nameEnglish: metadata.nameEnglish,
        nameTranslation: metadata.nameTranslation,
        revelationType: metadata.revelationType,
        numberOfAyahs: ayahs.length,
        ayahs: ayahs,
        startPage: ayahs.isNotEmpty ? ayahs.first.page : null,
      );
    } catch (e) {
      return _getMockSurahContent(surahNumber);
    }
  }

  @override
  Future<AyahEntity?> getAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final SurahContentEntity surah = await getSurahContent(surahNumber);
    return surah.getAyahByNumber(ayahNumber);
  }

  @override
  Future<QuranPageEntity> getPage(int pageNumber) async {
    await _ensureDataLoaded();

    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

    return QuranPageEntity(
      pageNumber: pageNumber,
      ayahs: [],
      juz: ((pageNumber - 1) ~/ 20) + 1,
      hizb: ((pageNumber - 1) ~/ 10) + 1,
    );
  }

  @override
  void updatePageWithWords(int pageNumber, Map<String, List<QuranWord>> words) {
    if (!_pageCache.containsKey(pageNumber)) return;

    final QuranPageEntity page = _pageCache[pageNumber]!;
    final List<PageAyahInfo> updatedAyahs = page.ayahs.map((ayah) {
      final verseKey = '${ayah.surahNumber}:${ayah.ayahNumber}';
      return ayah.copyWith(words: words[verseKey]);
    }).toList();

    _pageCache[pageNumber] = page.copyWith(ayahs: updatedAyahs);
  }

  @override
  Future<List<AyahEntity>> getJuz(int juzNumber) async {
    await _ensureDataLoaded();

    final List<AyahEntity> ayahs = [];

    if (_surahList == null || _surahList!.isEmpty) {
      return ayahs;
    }

    for (final surah in _surahList!) {
      final List<dynamic> surahAyahs = surah['ayahs'] as List<dynamic>? ?? [];

      for (final ayah in surahAyahs) {
        if (ayah['juz'] == juzNumber) {
          ayahs.add(
            AyahEntity(
              number: ayah['number'] ?? 0,
              numberInSurah: ayah['numberInSurah'] ?? 0,
              surahNumber: surah['number'] ?? 0,
              text: ayah['text'] ?? '',
              juz: ayah['juz'],
              page: ayah['page'],
            ),
          );
        }
      }
    }

    return ayahs;
  }

  @override
  Future<List<AyahEntity>> searchAyahs(String query) async {
    await _ensureDataLoaded();

    final List<AyahEntity> results = [];
    final String normalizedQuery = ArabicTextUtils.normalize(query);

    if (_surahList == null || _surahList!.isEmpty) {
      return results;
    }

    for (final surah in _surahList!) {
      final List<dynamic> surahAyahs = surah['ayahs'] as List<dynamic>? ?? [];

      for (final ayah in surahAyahs) {
        final String text = ayah['text']?.toString() ?? '';
        final String normalizedText = ArabicTextUtils.normalize(text);

        if (normalizedText.contains(normalizedQuery)) {
          results.add(
            AyahEntity(
              number: ayah['number'] ?? 0,
              numberInSurah: ayah['numberInSurah'] ?? 0,
              surahNumber: surah['number'] ?? 0,
              text: text,
              juz: ayah['juz'],
              page: ayah['page'],
            ),
          );
        }
      }
    }

    return results;
  }

  @override
  Future<List<SurahContentEntity>> searchSurahs(String query) async {
    await _ensureDataLoaded();

    final String normalizedQuery = ArabicTextUtils.normalize(
      query.toLowerCase(),
    );
    final List<SurahContentEntity> results = [];

    final Iterable<SurahMetadata> matchingSurahs = SurahMetadataRepository
        .allSurahs
        .where((surah) {
          final String normalizedAr = ArabicTextUtils.normalize(
            surah.nameArabic,
          );
          final String normalizedEn = surah.nameEnglish.toLowerCase();
          return normalizedAr.contains(normalizedQuery) ||
              normalizedEn.contains(normalizedQuery) ||
              surah.number.toString() == query.trim();
        });

    for (final surah in matchingSurahs) {
      int? startPage;
      if (_surahList != null && _surahList!.length >= surah.number) {
        final surahData = _surahList![surah.number - 1];
        final ayahs = surahData['ayahs'] as List?;
        if (ayahs != null && ayahs.isNotEmpty) {
          startPage = ayahs.first['page'] as int?;
        }
      }

      results.add(
        SurahContentEntity(
          number: surah.number,
          name: surah.nameArabic,
          nameEnglish: surah.nameEnglish,
          nameTranslation: surah.nameTranslation,
          revelationType: surah.revelationType,
          numberOfAyahs: surah.ayahCount,
          ayahs: const [],
          startPage: startPage,
        ),
      );
    }

    return results;
  }

  SurahContentEntity _getMockSurahContent(int surahNumber) {
    final SurahMetadata metadata = SurahMetadataRepository.getSurah(
      surahNumber,
    );

    final List<AyahEntity> ayahs = List.generate(
      metadata.ayahCount,
      (index) => AyahEntity(
        number: index + 1,
        numberInSurah: index + 1,
        surahNumber: surahNumber,
        text: 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
        juz: 1,
        page: 1,
      ),
    );

    return SurahContentEntity(
      number: surahNumber,
      name: metadata.nameArabic,
      nameEnglish: metadata.nameEnglish,
      nameTranslation: metadata.nameTranslation,
      revelationType: metadata.revelationType,
      numberOfAyahs: metadata.ayahCount,
      ayahs: ayahs,
    );
  }
}
