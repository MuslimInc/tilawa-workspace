import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';

void main() {
  group('AyahEntity', () {
    const ayah = AyahEntity(
      number: 1,
      numberInSurah: 1,
      surahNumber: 1,
      text: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      textUthmani: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      textSimple: 'بسم الله الرحمن الرحيم',
      translation: 'In the name of Allah',
      transliteration: 'Bismillaahir Rahmaanir Raheem',
      juz: 1,
      manzil: 1,
      page: 1,
      ruku: 1,
      hizbQuarter: 1,
      sajda: false,
    );

    test('arabicNumber should return correct Arabic numerals', () {
      expect(ayah.arabicNumber, '١');

      const ayah123 = AyahEntity(
        number: 123,
        numberInSurah: 123,
        surahNumber: 1,
        text: 'test',
      );
      expect(ayah123.arabicNumber, '١٢٣');
    });

    test('formattedNumber should include brackets', () {
      expect(ayah.formattedNumber, '﴿١﴾');
    });

    test('hasBasmala should return correct value', () {
      // Al-Fatiha, ayah 1 -> false
      expect(ayah.hasBasmala, isFalse);

      // Surah 2, ayah 1 -> true
      expect(
        const AyahEntity(
          number: 8,
          numberInSurah: 1,
          surahNumber: 2,
          text: 'test',
        ).hasBasmala,
        isTrue,
      );

      // Surah 9 (At-Tawba), ayah 1 -> false
      expect(
        const AyahEntity(
          number: 1235,
          numberInSurah: 1,
          surahNumber: 9,
          text: 'test',
        ).hasBasmala,
        isFalse,
      );

      // Surah 2, ayah 2 -> false
      expect(
        const AyahEntity(
          number: 9,
          numberInSurah: 2,
          surahNumber: 2,
          text: 'test',
        ).hasBasmala,
        isFalse,
      );
    });

    test('fromJson should work correctly', () {
      final Map<String, Object> json = {
        'number': 1,
        'numberInSurah': 1,
        'surahNumber': 1,
        'text': 'test',
        'textUthmani': 'uthmani',
        'textSimple': 'simple',
        'translation': 'translation',
        'transliteration': 'transliteration',
        'juz': 1,
        'manzil': 1,
        'page': 1,
        'ruku': 1,
        'hizbQuarter': 1,
        'sajda': false,
      };
      final entity = AyahEntity.fromJson(json);
      expect(entity.number, 1);
      expect(entity.text, 'test');
      expect(entity.textUthmani, 'uthmani');
      expect(entity.textSimple, 'simple');
      expect(entity.translation, 'translation');
      expect(entity.transliteration, 'transliteration');
      expect(entity.juz, 1);
      expect(entity.manzil, 1);
      expect(entity.page, 1);
      expect(entity.ruku, 1);
      expect(entity.hizbQuarter, 1);
      expect(entity.sajda, false);
    });

    test('toJson should work correctly', () {
      final Map<String, dynamic> json = ayah.toJson();
      expect(json['number'], 1);
      expect(json['numberInSurah'], 1);
      expect(json['surahNumber'], 1);
      expect(json['text'], 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ');
    });
  });

  group('ReaderSettingsEntity', () {
    const settings = ReaderSettingsEntity();

    test('fontFamily should return correct values', () {
      expect(settings.fontFamily, 'KFGQPC Uthmanic Script HAFS');
      expect(
        settings.copyWith(fontType: QuranFontType.indopak).fontFamily,
        'Noto Nastaliq Urdu',
      );
      expect(
        settings.copyWith(fontType: QuranFontType.simple).fontFamily,
        'Amiri',
      );
    });

    test('QuranFontType extension should return correct display names', () {
      expect(QuranFontType.uthmani.displayName, 'Uthmani');
      expect(QuranFontType.indopak.displayName, 'IndoPak');
      expect(QuranFontType.simple.displayName, 'Simple');

      expect(QuranFontType.uthmani.displayNameAr, 'عثماني');
      expect(QuranFontType.indopak.displayNameAr, 'إندوباكي');
      expect(QuranFontType.simple.displayNameAr, 'بسيط');
    });

    test('ReadingMode extension should return correct display names', () {
      expect(ReadingMode.surah.displayName, 'Surah');
      expect(ReadingMode.page.displayName, 'Page');
      expect(ReadingMode.juz.displayName, 'Juz');

      expect(ReadingMode.surah.displayNameAr, 'سورة');
      expect(ReadingMode.page.displayNameAr, 'صفحة');
      expect(ReadingMode.juz.displayNameAr, 'جزء');
    });

    test('fromJson should work correctly', () {
      final Map<String, Object> json = {
        'fontSize': 20.0,
        'lineHeight': 1.5,
        'fontType': 'uthmani',
        'readingMode': 'surah',
        'showTranslation': true,
        'translationLanguage': 'en',
        'showTransliteration': false,
        'showAyahNumbers': true,
        'nightMode': false,
        'translationFontSize': 1.0,
        'lastReadSurah': 1,
        'lastReadAyah': 1,
        'lastReadPage': 1,
      };
      final entity = ReaderSettingsEntity.fromJson(json);
      expect(entity.fontSize, 20.0);
      expect(entity.fontType, QuranFontType.uthmani);
      expect(entity.readingMode, ReadingMode.surah);
      expect(entity.lastReadSurah, 1);
      expect(entity.lastReadAyah, 1);
      expect(entity.lastReadPage, 1);
    });

    test('toJson should work correctly', () {
      final Map<String, dynamic> json = settings.toJson();
      expect(json['fontSize'], 24.0);
      expect(json['fontType'], 'uthmani');
      expect(json['readingMode'], 'surah');
    });
  });

  group('SurahContentEntity', () {
    const surah = SurahContentEntity(
      number: 1,
      name: 'الفاتحة',
      nameEnglish: 'Al-Fatiha',
      nameTranslation: 'The Opening',
      revelationType: 'Meccan',
      numberOfAyahs: 7,
      ayahs: [
        AyahEntity(number: 1, numberInSurah: 1, surahNumber: 1, text: 'test'),
      ],
      startPage: 1,
      endPage: 1,
    );

    test('isMeccan and isMedinan should return correct values', () {
      expect(surah.isMeccan, isTrue);
      expect(surah.isMedinan, isFalse);

      final SurahContentEntity medinan = surah.copyWith(
        revelationType: 'Medinan',
      );
      expect(medinan.isMeccan, isFalse);
      expect(medinan.isMedinan, isTrue);
    });

    test('getAyahByNumber should return ayah or null', () {
      expect(surah.getAyahByNumber(1), isNotNull);
      expect(surah.getAyahByNumber(2), isNull);
    });

    test('fromJson should work for all nested entities', () {
      final Map<String, Object> json = {
        'number': 1,
        'name': 'test',
        'nameEnglish': 'test',
        'nameTranslation': 'test',
        'revelationType': 'meccan',
        'numberOfAyahs': 1,
        'ayahs': [
          {'number': 1, 'numberInSurah': 1, 'surahNumber': 1, 'text': 'test'},
        ],
        'startPage': 1,
        'endPage': 1,
      };
      final entity = SurahContentEntity.fromJson(json);
      expect(entity.number, 1);
      expect(entity.ayahs.length, 1);
      expect(entity.startPage, 1);
      expect(entity.endPage, 1);
    });

    test('toJson should work correctly', () {
      final Map<String, dynamic> json = surah.toJson();
      expect(json['number'], 1);
      expect(json['ayahs'], isList);
    });
  });

  group('QuranPageEntity', () {
    test('fromJson should work', () {
      final Map<String, Object> json = {
        'pageNumber': 1,
        'juz': 1,
        'hizb': 1,
        'ayahs': [
          {
            'surahNumber': 1,
            'surahName': 'test',
            'surahNameEnglish': 'test',
            'ayahNumber': 1,
            'text': 'test',
            'words': [
              {
                'id': 1,
                'position': 1,
                'text': 'test',
                'text_uthmani': 'uthmani',
                'audio_url': 'url',
                'code_v1': 'v1',
                'char_type_name': 'word',
                'translation': {'text': 'translation', 'language_name': 'en'},
                'transliteration': {
                  'text': 'transliteration',
                  'language_name': 'en',
                },
              },
            ],
          },
        ],
      };
      final entity = QuranPageEntity.fromJson(json);
      expect(entity.pageNumber, 1);
      final QuranWord word = entity.ayahs.first.words!.first;
      expect(word.text, 'test');
      expect(word.textUthmani, 'uthmani');
      expect(word.audioUrl, 'url');
      expect(word.codeV1, 'v1');
      expect(word.charTypeName, 'word');
      expect(word.translation!.text, 'translation');
      expect(word.translation!.languageName, 'en');
      expect(word.transliteration!.text, 'transliteration');
      expect(word.transliteration!.languageName, 'en');

      final jsonNullTrans = Map<String, dynamic>.from(json);
      (jsonNullTrans['ayahs'] as List)[0]['words'][0]['transliteration'] = {
        'text': null,
        'language_name': null,
      };
      final entityNullTrans = QuranPageEntity.fromJson(jsonNullTrans);
      expect(
        entityNullTrans.ayahs.first.words!.first.transliteration!.text,
        isNull,
      );
    });

    test('toJson should work', () {
      const page = QuranPageEntity(
        pageNumber: 1,
        juz: 1,
        hizb: 1,
        ayahs: [
          PageAyahInfo(
            surahNumber: 1,
            surahName: 'test',
            surahNameEnglish: 'test',
            ayahNumber: 1,
            text: 'test',
            words: [
              QuranWord(
                id: 1,
                position: 1,
                text: 'test',
                translation: WordTranslation(text: 'trans'),
              ),
            ],
          ),
        ],
      );
      final Map<String, dynamic> json = page.toJson();
      expect(json['pageNumber'], 1);
      expect(json['ayahs'], isList);
    });
  });

  group('BasmalaEntity', () {
    test('should have correct static values', () {
      expect(BasmalaEntity.text, isNotEmpty);
      expect(BasmalaEntity.translation, isNotEmpty);
    });
  });
}
