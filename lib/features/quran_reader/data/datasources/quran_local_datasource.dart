import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/entities.dart';
import '../models/surah_metadata.dart';
import 'arabic_text_utils.dart';

// Top-level function for compute
Map<String, dynamic> _parseJson(String jsonString) {
  return jsonDecode(jsonString) as Map<String, dynamic>;
}

String _encodeJson(Map<String, dynamic> json) {
  return jsonEncode(json);
}

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

  /// Gets all pages.
  Future<Map<int, QuranPageEntity>> getAllPages();

  /// Gets all ayahs for a specific juz.
  Future<List<AyahEntity>> getJuz(int juzNumber);

  /// Searches ayahs by text query.
  Future<List<AyahEntity>> searchAyahs(String query);

  /// Searches surahs by name or number.
  Future<List<SurahContentEntity>> searchSurahs(String query);

  /// Updates page cache with word data.

  Future<void> updatePageWithWords(
    int pageNumber,
    Map<String, List<QuranWord>> words,
  );
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
    if (_quranData != null) {
      return;
    }

    try {
      final String jsonString = await _assetBundle.loadString(
        'assets/data/quran.json',
      );

      final Map<String, dynamic> parsed = await compute(_parseJson, jsonString);

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
    if (_surahList == null || _surahList!.isEmpty) {
      return;
    }

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
        if (page == 0) {
          continue;
        }

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
      if (_pageCache.containsKey(i)) {
        continue;
      }

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

  Directory? _cacheDir;

  Future<void> _initCacheDir() async {
    if (_cacheDir != null) {
      return;
    }
    try {
      final Directory docsDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${docsDir.path}/quran_pages_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error initializing cache dir: $e');
    }
  }

  Future<QuranPageEntity?> _loadPageFromDisk(int pageNumber) async {
    try {
      await _initCacheDir();
      if (_cacheDir == null) {
        return null;
      }

      final file = File('${_cacheDir!.path}/$pageNumber.json');
      if (await file.exists()) {
        final String jsonString = await file.readAsString();
        if (jsonString.isEmpty) {
          return null;
        }

        final Map<String, dynamic> jsonMap = await compute(
          _parseJson,
          jsonString,
        );
        final diskPage = QuranPageEntity.fromJson(jsonMap);

        // Check for invalid cache (missing rendered properties)
        // If we find corrupted words (e.g. renderedText is null), repair them.
        final bool needsRepair = diskPage.ayahs
            .expand<QuranWord>((a) => a.words ?? [])
            .any((w) => w.renderedText == null && w.charTypeName != 'end');

        if (needsRepair) {
          debugPrint('Repairing invalidated cache for page $pageNumber');
          final QuranPageEntity repairedPage = _repairPage(diskPage);
          // Save repaired version back to disk
          await _savePageToDisk(repairedPage);
          return repairedPage;
        }

        return diskPage;
      }
    } catch (e) {
      debugPrint('Error loading page $pageNumber from disk: $e');
    }
    return null;
  }

  QuranPageEntity _repairPage(QuranPageEntity page) {
    // Pre-compute font family for this page (QCF fonts are page-specific)
    final pageFont = 'QCF_P${page.pageNumber.toString().padLeft(3, '0')}';

    final List<PageAyahInfo> updatedAyahs = page.ayahs.map((ayah) {
      if (ayah.words == null) return ayah;

      final List<QuranWord> processedWords = ayah.words!.map((word) {
        // If already has renderedText, keep it (unless we want to force refresh?
        // Safe to re-compute to be sure).
        final bool hasCodeV1 = word.codeV1 != null && word.codeV1!.isNotEmpty;
        return word.copyWith(
          renderedText: hasCodeV1
              ? word.codeV1
              : (word.textUthmani ?? word.text),
          fontFamily: hasCodeV1 ? pageFont : 'Amiri',
          lineHeight: hasCodeV1 ? 1.6 : 2.2,
        );
      }).toList();

      return ayah.copyWith(words: processedWords);
    }).toList();

    return page.copyWith(ayahs: updatedAyahs);
  }

  Future<void> _savePageToDisk(QuranPageEntity page) async {
    try {
      await _initCacheDir();
      if (_cacheDir == null) {
        return;
      }

      final file = File('${_cacheDir!.path}/${page.pageNumber}.json');
      final Map<String, dynamic> jsonMap = page.toJson();
      final String jsonString = await compute(_encodeJson, jsonMap);
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving page ${page.pageNumber} to disk: $e');
    }
  }

  @override
  Future<QuranPageEntity> getPage(int pageNumber) async {
    QuranPageEntity? memoryPage;

    // 1. Check Memory
    if (_pageCache.containsKey(pageNumber)) {
      memoryPage = _pageCache[pageNumber];
      if (memoryPage != null) {
        // If we have fully enriched words, return immediately
        final bool hasWords =
            memoryPage.ayahs.isNotEmpty &&
            memoryPage.ayahs.first.words != null &&
            memoryPage.ayahs.first.words!.isNotEmpty;

        if (hasWords) {
          return memoryPage;
        }
      }
    }

    // 2. Check Disk (if memory is missing or incomplete)
    // _savePageToDisk is only called for enriched pages, so any disk hit is better than raw memory
    final QuranPageEntity? diskPage = await _loadPageFromDisk(pageNumber);
    if (diskPage != null) {
      _pageCache[pageNumber] = diskPage;
      // Trigger asset loading in background to populate surah lists/metadata if needed
      await _ensureDataLoaded();
      return diskPage;
    }

    // 3. Fallback to Memory (if we had a raw version)
    if (memoryPage != null) {
      return memoryPage;
    }

    // 4. Fallback to Asset
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
  Future<Map<int, QuranPageEntity>> getAllPages() async {
    await _ensureDataLoaded();
    return Map.from(_pageCache);
  }

  @override
  Future<void> updatePageWithWords(
    int pageNumber,
    Map<String, List<QuranWord>> words,
  ) async {
    if (!_pageCache.containsKey(pageNumber)) {
      return;
    }

    // Pre-compute font family for this page (QCF fonts are page-specific)
    final pageFont = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';

    final QuranPageEntity page = _pageCache[pageNumber]!;
    final List<PageAyahInfo> updatedAyahs = page.ayahs.map((ayah) {
      final verseKey = '${ayah.surahNumber}:${ayah.ayahNumber}';
      final List<QuranWord>? ayahWords = words[verseKey];

      if (ayahWords == null) {
        return ayah;
      }

      // Pre-compute rendering values for each word
      final List<QuranWord> processedWords = ayahWords.map((word) {
        final bool hasCodeV1 = word.codeV1 != null && word.codeV1!.isNotEmpty;
        return word.copyWith(
          renderedText: hasCodeV1
              ? word.codeV1
              : (word.textUthmani ?? word.text),
          fontFamily: hasCodeV1 ? pageFont : 'Amiri',
          lineHeight: hasCodeV1 ? 1.6 : 2.2,
        );
      }).toList();

      return ayah.copyWith(words: processedWords);
    }).toList();

    final QuranPageEntity updatedPage = page.copyWith(ayahs: updatedAyahs);
    _pageCache[pageNumber] = updatedPage;

    // Persist to disk
    await _savePageToDisk(updatedPage);
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
