import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/entities.dart';

abstract class QuranDataSource {
  Future<SurahContentEntity> getSurahContent(int surahNumber);

  Future<AyahEntity?> getAyah({
    required int surahNumber,

    required int ayahNumber,
  });

  Future<QuranPageEntity> getPage(int pageNumber);

  Future<List<AyahEntity>> getJuz(int juzNumber);

  Future<List<AyahEntity>> searchAyahs(String query);

  Future<List<SurahContentEntity>> searchSurahs(String query);

  Future<Map<String, List<QuranWord>>> getPageWords(int pageNumber);
}

@LazySingleton(as: QuranDataSource)
class QuranDataSourceImpl implements QuranDataSource {
  QuranDataSourceImpl({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Map<String, dynamic>? _quranData;

  List<dynamic>? _surahList;

  final Map<int, QuranPageEntity> _pageCache = {};

  /// Load Quran data from assets

  Future<void> _ensureDataLoaded() async {
    if (_quranData != null) return;

    try {
      // Try to load from bundled asset

      final String jsonString = await rootBundle.loadString(
        'assets/data/quran.json',
      );

      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;

      // The API response wraps surahs inside 'data' -> 'surahs'

      if (parsed.containsKey('data') && parsed['data'] is Map) {
        _quranData = parsed;

        _surahList = parsed['data']['surahs'] as List<dynamic>?;
      } else if (parsed.containsKey('surahs')) {
        // Direct format without API wrapper

        _quranData = parsed;

        _surahList = parsed['surahs'] as List<dynamic>?;
      } else {
        throw const FormatException('Unexpected Quran data format');
      }

      // Pre-calculate all pages

      _preloadPages();
    } catch (e) {
      // If file doesn't exist or parse error, initialize with empty structure

      _quranData = {
        'data': {'surahs': []},
      };

      _surahList = [];
    }
  }

  void _preloadPages() {
    if (_surahList == null || _surahList!.isEmpty) return;

    // Temporary map to hold ayahs for each page

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

        if (!pageAyahsMap.containsKey(page)) {
          pageAyahsMap[page] = [];
        }

        // Capture Juz/Hizb for the page if not already set

        // (Using the first ayah of the page effectively)

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

    // Convert to QuranPageEntity

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
      // Return mock data for demonstration

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

      // Use cleaner surah name from the info list if available

      final _SurahInfo surahInfo = surahNumber <= _surahInfoList.length
          ? _surahInfoList[surahNumber - 1]
          : _SurahInfo(
              surahData['name'] ?? '',

              surahData['englishName'] ?? '',

              surahData['englishNameTranslation'] ?? '',

              surahData['revelationType'] ?? 'Meccan',

              ayahs.length,
            );

      return SurahContentEntity(
        number: surahNumber,

        name: surahInfo.nameAr,

        nameEnglish: surahInfo.nameEn,

        nameTranslation: surahInfo.meaning,

        revelationType: surahInfo.type,

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
      final QuranPageEntity page = _pageCache[pageNumber]!;

      // If words are already loaded for this page, return it

      if (page.ayahs.isNotEmpty && page.ayahs.first.words != null) {
        return page;
      }

      // Fetch words and update the cached page

      try {
        final Map<String, List<QuranWord>> wordMap = await getPageWords(
          pageNumber,
        );

        if (wordMap.isNotEmpty) {
          final List<PageAyahInfo> updatedAyahs = page.ayahs.map((ayah) {
            final verseKey = '${ayah.surahNumber}:${ayah.ayahNumber}';

            return ayah.copyWith(words: wordMap[verseKey]);
          }).toList();

          final QuranPageEntity updatedPage = page.copyWith(
            ayahs: updatedAyahs,
          );

          _pageCache[pageNumber] = updatedPage;

          return updatedPage;
        }
      } catch (e) {
        // Fallback to text only if words fetch fails

        return page;
      }

      return page;
    }

    // Fallback if cache missed (should not happen if preload works)

    return QuranPageEntity(
      pageNumber: pageNumber,

      ayahs: [],

      juz: ((pageNumber - 1) ~/ 20) + 1,

      hizb: ((pageNumber - 1) ~/ 10) + 1,
    );
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

    final String normalizedQuery = _normalizeArabic(query);

    if (_surahList == null || _surahList!.isEmpty) {
      return results;
    }

    for (final surah in _surahList!) {
      final List<dynamic> surahAyahs = surah['ayahs'] as List<dynamic>? ?? [];

      for (final ayah in surahAyahs) {
        final String text = ayah['text']?.toString() ?? '';

        final String normalizedText = _normalizeArabic(text);

        if (normalizedText.contains(normalizedQuery)) {
          results.add(
            AyahEntity(
              number: ayah['number'] ?? 0,

              numberInSurah: ayah['numberInSurah'] ?? 0,

              surahNumber: surah['number'] ?? 0,

              text: text, // Return original text for display

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

    final String normalizedQuery = _normalizeArabic(query.toLowerCase());

    final List<SurahContentEntity> results = [];

    // Filter _surahInfoList directly

    for (var i = 0; i < _surahInfoList.length; i++) {
      final _SurahInfo info = _surahInfoList[i];

      final int surahNumber = i + 1;

      final String nameAr = info.nameAr;

      final String nameEn = info.nameEn;

      final String nameEnLower = nameEn.toLowerCase();

      final String normalizedNameAr = _normalizeArabic(nameAr);

      final String normalizedNameEn = _normalizeArabic(nameEnLower);

      if (normalizedNameAr.contains(normalizedQuery) ||
          normalizedNameEn.contains(normalizedQuery) ||
          surahNumber.toString() == normalizedQuery) {
        // We construct a lightweight entity (no ayahs) for search results

        // Or we can fetch the full content if needed, but for search list lightweight is better.

        // However, SurahContentEntity requires list of Ayahs. We can pass empty for now.

        results.add(
          SurahContentEntity(
            number: surahNumber,

            name: nameAr,

            nameEnglish: nameEn,

            nameTranslation: info.meaning,

            revelationType: info.type,

            numberOfAyahs: info.ayahCount,

            ayahs: const [],

            startPage: _surahList != null && _surahList!.length >= surahNumber
                ? (_surahList![i]['ayahs'] as List).first['page'] as int
                : null,
          ),
        );
      }
    }

    return results;
  }

  /// Normalizes Arabic text by removing diacritics and unifying Alef forms

  String _normalizeArabic(String text) {
    if (text.isEmpty) return text;

    var normalized = text;

    // Remove diacritics (Tashkeel)

    // Range includes Fatha, Damma, Kasra, Sukun, Shadda, Tanwin, etc.

    // Also removes Quranic specific marks like superscript Alef

    normalized = normalized.replaceAll(
      RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'),

      '',
    );

    // Normalize Alef forms (أ, إ, آ -> ا)

    normalized = normalized.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // Normalize Ya/Alef Maqsura (ى -> ي) - Optional but good for looser search

    normalized = normalized.replaceAll('ى', 'ي');

    // Normalize Ta Marbuta (ة -> ه) - Optional but good for looser search

    normalized = normalized.replaceAll('ة', 'ه');

    return normalized;
  }

  /// Generate mock surah content for demonstration

  SurahContentEntity _getMockSurahContent(int surahNumber) {
    final _SurahInfo surahInfo = _surahInfoList[surahNumber - 1];

    // Generate sample ayahs

    final List<AyahEntity> ayahs = List.generate(
      surahInfo.ayahCount,

      (index) => AyahEntity(
        number: index + 1,

        numberInSurah: index + 1,

        surahNumber: surahNumber,

        text: 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ', // Placeholder text

        juz: 1,

        page: 1,
      ),
    );

    return SurahContentEntity(
      number: surahNumber,

      name: surahInfo.nameAr,

      nameEnglish: surahInfo.nameEn,

      nameTranslation: surahInfo.meaning,

      revelationType: surahInfo.type,

      numberOfAyahs: surahInfo.ayahCount,

      ayahs: ayahs,
    );
  }

  @override
  Future<Map<String, List<QuranWord>>> getPageWords(int pageNumber) async {
    try {
      final Response<dynamic> response = await _dio.get(
        'https://api.quran.com/api/v4/verses/by_page/$pageNumber',

        queryParameters: {'words': true, 'word_fields': 'text_uthmani,code_v1'},
      );

      final data = response.data;

      if (data == null || data['verses'] == null) {
        return {};
      }

      final Map<String, List<QuranWord>> result = {};

      final verses = data['verses'] as List;

      for (final verse in verses) {
        final verseKey = verse['verse_key'] as String;

        final wordsData = verse['words'] as List?;

        if (wordsData != null) {
          final List<QuranWord> words = wordsData
              .map((w) => QuranWord.fromJson(w as Map<String, dynamic>))
              .toList();

          result[verseKey] = words;
        }
      }

      return result;
    } catch (e) {
      // In a real app, handle error properly. For prototype, return empty.

      return {};
    }
  }
}

/// Basic surah information

class _SurahInfo {
  const _SurahInfo(
    this.nameAr,

    this.nameEn,

    this.meaning,

    this.type,

    this.ayahCount,
  );

  final String nameAr;

  final String nameEn;

  final String meaning;

  final String type;

  final int ayahCount;
}

const List<_SurahInfo> _surahInfoList = [
  _SurahInfo('الفاتحة', 'Al-Fatiha', 'The Opening', 'Meccan', 7),

  _SurahInfo('البقرة', 'Al-Baqara', 'The Cow', 'Medinan', 286),

  _SurahInfo('آل عمران', 'Aal-Imran', 'The Family of Imran', 'Medinan', 200),

  _SurahInfo('النساء', 'An-Nisa', 'The Women', 'Medinan', 176),

  _SurahInfo('المائدة', 'Al-Maida', 'The Table Spread', 'Medinan', 120),

  _SurahInfo('الأنعام', 'Al-Anam', 'The Cattle', 'Meccan', 165),

  _SurahInfo('الأعراف', 'Al-Araf', 'The Heights', 'Meccan', 206),

  _SurahInfo('الأنفال', 'Al-Anfal', 'The Spoils of War', 'Medinan', 75),

  _SurahInfo('التوبة', 'At-Tawba', 'The Repentance', 'Medinan', 129),

  _SurahInfo('يونس', 'Yunus', 'Jonah', 'Meccan', 109),

  _SurahInfo('هود', 'Hud', 'Hud', 'Meccan', 123),

  _SurahInfo('يوسف', 'Yusuf', 'Joseph', 'Meccan', 111),

  _SurahInfo('الرعد', 'Ar-Rad', 'The Thunder', 'Medinan', 43),

  _SurahInfo('إبراهيم', 'Ibrahim', 'Abraham', 'Meccan', 52),

  _SurahInfo('الحجر', 'Al-Hijr', 'The Rocky Tract', 'Meccan', 99),

  _SurahInfo('النحل', 'An-Nahl', 'The Bee', 'Meccan', 128),

  _SurahInfo('الإسراء', 'Al-Isra', 'The Night Journey', 'Meccan', 111),

  _SurahInfo('الكهف', 'Al-Kahf', 'The Cave', 'Meccan', 110),

  _SurahInfo('مريم', 'Maryam', 'Mary', 'Meccan', 98),

  _SurahInfo('طه', 'Taha', 'Ta-Ha', 'Meccan', 135),

  _SurahInfo('الأنبياء', 'Al-Anbiya', 'The Prophets', 'Meccan', 112),

  _SurahInfo('الحج', 'Al-Hajj', 'The Pilgrimage', 'Medinan', 78),

  _SurahInfo('المؤمنون', 'Al-Muminun', 'The Believers', 'Meccan', 118),

  _SurahInfo('النور', 'An-Nur', 'The Light', 'Medinan', 64),

  _SurahInfo('الفرقان', 'Al-Furqan', 'The Criterion', 'Meccan', 77),

  _SurahInfo('الشعراء', 'Ash-Shuara', 'The Poets', 'Meccan', 227),

  _SurahInfo('النمل', 'An-Naml', 'The Ant', 'Meccan', 93),

  _SurahInfo('القصص', 'Al-Qasas', 'The Stories', 'Meccan', 88),

  _SurahInfo('العنكبوت', 'Al-Ankabut', 'The Spider', 'Meccan', 69),

  _SurahInfo('الروم', 'Ar-Rum', 'The Romans', 'Meccan', 60),

  _SurahInfo('لقمان', 'Luqman', 'Luqman', 'Meccan', 34),

  _SurahInfo('السجدة', 'As-Sajda', 'The Prostration', 'Meccan', 30),

  _SurahInfo('الأحزاب', 'Al-Ahzab', 'The Combined Forces', 'Medinan', 73),

  _SurahInfo('سبأ', 'Saba', 'Sheba', 'Meccan', 54),

  _SurahInfo('فاطر', 'Fatir', 'Originator', 'Meccan', 45),

  _SurahInfo('يس', 'Ya-Sin', 'Ya Sin', 'Meccan', 83),

  _SurahInfo('الصافات', 'As-Saffat', 'Those Who Set The Ranks', 'Meccan', 182),

  _SurahInfo('ص', 'Sad', 'Sad', 'Meccan', 88),

  _SurahInfo('الزمر', 'Az-Zumar', 'The Troops', 'Meccan', 75),

  _SurahInfo('غافر', 'Ghafir', 'The Forgiver', 'Meccan', 85),

  _SurahInfo('فصلت', 'Fussilat', 'Explained in Detail', 'Meccan', 54),

  _SurahInfo('الشورى', 'Ash-Shura', 'The Consultation', 'Meccan', 53),

  _SurahInfo('الزخرف', 'Az-Zukhruf', 'The Ornaments of Gold', 'Meccan', 89),

  _SurahInfo('الدخان', 'Ad-Dukhan', 'The Smoke', 'Meccan', 59),

  _SurahInfo('الجاثية', 'Al-Jathiya', 'The Crouching', 'Meccan', 37),

  _SurahInfo('الأحقاف', 'Al-Ahqaf', 'The Wind-Curved Sandhills', 'Meccan', 35),

  _SurahInfo('محمد', 'Muhammad', 'Muhammad', 'Medinan', 38),

  _SurahInfo('الفتح', 'Al-Fath', 'The Victory', 'Medinan', 29),

  _SurahInfo('الحجرات', 'Al-Hujurat', 'The Rooms', 'Medinan', 18),

  _SurahInfo('ق', 'Qaf', 'Qaf', 'Meccan', 45),

  _SurahInfo('الذاريات', 'Adh-Dhariyat', 'The Winnowing Winds', 'Meccan', 60),

  _SurahInfo('الطور', 'At-Tur', 'The Mount', 'Meccan', 49),

  _SurahInfo('النجم', 'An-Najm', 'The Star', 'Meccan', 62),

  _SurahInfo('القمر', 'Al-Qamar', 'The Moon', 'Meccan', 55),

  _SurahInfo('الرحمن', 'Ar-Rahman', 'The Beneficent', 'Medinan', 78),

  _SurahInfo('الواقعة', 'Al-Waqia', 'The Inevitable', 'Meccan', 96),

  _SurahInfo('الحديد', 'Al-Hadid', 'The Iron', 'Medinan', 29),

  _SurahInfo('المجادلة', 'Al-Mujadila', 'The Pleading Woman', 'Medinan', 22),

  _SurahInfo('الحشر', 'Al-Hashr', 'The Exile', 'Medinan', 24),

  _SurahInfo(
    'الممتحنة',

    'Al-Mumtahana',

    'She That Is To Be Examined',

    'Medinan',

    13,
  ),

  _SurahInfo('الصف', 'As-Saf', 'The Ranks', 'Medinan', 14),

  _SurahInfo('الجمعة', 'Al-Jumua', 'The Congregation', 'Medinan', 11),

  _SurahInfo('المنافقون', 'Al-Munafiqun', 'The Hypocrites', 'Medinan', 11),

  _SurahInfo('التغابن', 'At-Taghabun', 'The Mutual Disillusion', 'Medinan', 18),

  _SurahInfo('الطلاق', 'At-Talaq', 'The Divorce', 'Medinan', 12),

  _SurahInfo('التحريم', 'At-Tahrim', 'The Prohibition', 'Medinan', 12),

  _SurahInfo('الملك', 'Al-Mulk', 'The Sovereignty', 'Meccan', 30),

  _SurahInfo('القلم', 'Al-Qalam', 'The Pen', 'Meccan', 52),

  _SurahInfo('الحاقة', 'Al-Haaqqa', 'The Reality', 'Meccan', 52),

  _SurahInfo('المعارج', 'Al-Maarij', 'The Ascending Stairways', 'Meccan', 44),

  _SurahInfo('نوح', 'Nuh', 'Noah', 'Meccan', 28),

  _SurahInfo('الجن', 'Al-Jinn', 'The Jinn', 'Meccan', 28),

  _SurahInfo('المزمل', 'Al-Muzzammil', 'The Enshrouded One', 'Meccan', 20),

  _SurahInfo('المدثر', 'Al-Muddaththir', 'The Cloaked One', 'Meccan', 56),

  _SurahInfo('القيامة', 'Al-Qiyama', 'The Resurrection', 'Meccan', 40),

  _SurahInfo('الإنسان', 'Al-Insan', 'The Human', 'Medinan', 31),

  _SurahInfo('المرسلات', 'Al-Mursalat', 'The Emissaries', 'Meccan', 50),

  _SurahInfo('النبأ', 'An-Naba', 'The Tidings', 'Meccan', 40),

  _SurahInfo('النازعات', 'An-Naziat', 'Those Who Drag Forth', 'Meccan', 46),

  _SurahInfo('عبس', 'Abasa', 'He Frowned', 'Meccan', 42),

  _SurahInfo('التكوير', 'At-Takwir', 'The Overthrowing', 'Meccan', 29),

  _SurahInfo('الانفطار', 'Al-Infitar', 'The Cleaving', 'Meccan', 19),

  _SurahInfo('المطففين', 'Al-Mutaffifin', 'The Defrauding', 'Meccan', 36),

  _SurahInfo('الانشقاق', 'Al-Inshiqaq', 'The Sundering', 'Meccan', 25),

  _SurahInfo('البروج', 'Al-Buruj', 'The Mansions of the Stars', 'Meccan', 22),

  _SurahInfo('الطارق', 'At-Tariq', 'The Morning Star', 'Meccan', 17),

  _SurahInfo('الأعلى', 'Al-Ala', 'The Most High', 'Meccan', 19),

  _SurahInfo('الغاشية', 'Al-Ghashiya', 'The Overwhelming', 'Meccan', 26),

  _SurahInfo('الفجر', 'Al-Fajr', 'The Dawn', 'Meccan', 30),

  _SurahInfo('البلد', 'Al-Balad', 'The City', 'Meccan', 20),

  _SurahInfo('الشمس', 'Ash-Shams', 'The Sun', 'Meccan', 15),

  _SurahInfo('الليل', 'Al-Layl', 'The Night', 'Meccan', 21),

  _SurahInfo('الضحى', 'Ad-Duha', 'The Morning Hours', 'Meccan', 11),

  _SurahInfo('الشرح', 'Ash-Sharh', 'The Relief', 'Meccan', 8),

  _SurahInfo('التين', 'At-Tin', 'The Fig', 'Meccan', 8),

  _SurahInfo('العلق', 'Al-Alaq', 'The Clot', 'Meccan', 19),

  _SurahInfo('القدر', 'Al-Qadr', 'The Power', 'Meccan', 5),

  _SurahInfo('البينة', 'Al-Bayyina', 'The Clear Proof', 'Medinan', 8),

  _SurahInfo('الزلزلة', 'Az-Zalzala', 'The Earthquake', 'Medinan', 8),

  _SurahInfo('العاديات', 'Al-Adiyat', 'The Courser', 'Meccan', 11),

  _SurahInfo('القارعة', 'Al-Qaria', 'The Calamity', 'Meccan', 11),

  _SurahInfo(
    'التكاثر',

    'At-Takathur',

    'The Rivalry in World Increase',

    'Meccan',

    8,
  ),

  _SurahInfo('العصر', 'Al-Asr', 'The Declining Day', 'Meccan', 3),

  _SurahInfo('الهمزة', 'Al-Humaza', 'The Traducer', 'Meccan', 9),

  _SurahInfo('الفيل', 'Al-Fil', 'The Elephant', 'Meccan', 5),

  _SurahInfo('قريش', 'Quraysh', 'Quraysh', 'Meccan', 4),

  _SurahInfo('الماعون', 'Al-Maun', 'The Small Kindnesses', 'Meccan', 7),

  _SurahInfo('الكوثر', 'Al-Kawthar', 'The Abundance', 'Meccan', 3),

  _SurahInfo('الكافرون', 'Al-Kafirun', 'The Disbelievers', 'Meccan', 6),

  _SurahInfo('النصر', 'An-Nasr', 'The Divine Support', 'Medinan', 3),

  _SurahInfo('المسد', 'Al-Masad', 'The Palm Fiber', 'Meccan', 5),

  _SurahInfo('الإخلاص', 'Al-Ikhlas', 'The Sincerity', 'Meccan', 4),

  _SurahInfo('الفلق', 'Al-Falaq', 'The Daybreak', 'Meccan', 5),

  _SurahInfo('الناس', 'An-Nas', 'Mankind', 'Meccan', 6),
];
