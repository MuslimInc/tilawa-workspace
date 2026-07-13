import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/daily_guidance/data/mappers/daily_guidance_content_validator.dart';
import 'package:tilawa/features/daily_guidance/data/datasources/daily_guidance_seed_data_source.dart';
import 'package:tilawa/features/daily_guidance/data/models/content_review_metadata_model.dart';
import 'package:tilawa/features/daily_guidance/data/models/daily_guidance_item_model.dart';
import 'package:tilawa/features/daily_guidance/data/models/hadith_source_metadata_model.dart';
import 'package:tilawa/features/daily_guidance/data/models/quran_source_metadata_model.dart';
import 'package:tilawa/features/daily_guidance/domain/entities/daily_guidance_enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const validator = DailyGuidanceContentValidator();

  group('DailyGuidanceContentValidator', () {
    test('every seed item passes each supported trust boundary', () async {
      final models = await DailyGuidanceSeedDataSource().loadSeedItems();

      check(models).length.equals(6);
      check(models.map((model) => model.id).toSet()).length.equals(6);
      for (final model in models) {
        for (final locale in const ['ar', 'en']) {
          for (final capability in DailyGuidanceCapability.values) {
            check(
              validator.validate(
                model: model,
                locale: locale,
                capability: capability,
              ),
            ).isNotNull();
          }
        }
      }
    });

    test('locale variants normalize without cross-language fallback', () {
      for (final locale in const ['ar-EG', 'ar_SA']) {
        check(
          validator.validate(
            model: _quranModel(),
            locale: locale,
            capability: DailyGuidanceCapability.display,
          ),
        ).isNotNull();
      }
      for (final locale in const ['en-US', 'en_GB']) {
        final trusted = validator.validate(
          model: _quranModel(),
          locale: locale,
          capability: DailyGuidanceCapability.display,
        );
        check(trusted).isNotNull();
        check(trusted!.translation!.text).equals('Translation');
      }
      check(
        validator.validate(
          model: _quranModel(),
          locale: 'fr-FR',
          capability: DailyGuidanceCapability.display,
        ),
      ).isNull();
    });

    test('verified Quran crosses the display trust boundary', () {
      final trusted = validator.validate(
        model: _quranModel(),
        locale: 'ar',
        capability: DailyGuidanceCapability.display,
      );

      check(trusted).isNotNull();
      check(trusted!.translation).isNull();
      check(trusted.shortExplanation!.locale).equals('ar');
      check(trusted.shortExplanation!.text).equals('شرح عربي');
      check(trusted.shortExplanation!.sourceId).equals('tilawa:editorial:v1');
    });

    test('Arabic Hadith uses an Arabic collection name', () {
      final trusted = validator.validate(
        model: _hadithModel(),
        locale: 'ar',
        capability: DailyGuidanceCapability.display,
      );

      check(trusted).isNotNull();
      check(trusted!.hadithSource!.collection).equals('صحيح البخاري');
      check(trusted.translation).isNull();
    });

    test('English display keeps only the validated English values', () {
      final trusted = validator.validate(
        model: _quranModel(),
        locale: 'en',
        capability: DailyGuidanceCapability.display,
      );

      check(trusted).isNotNull();
      check(trusted!.translation!.locale).equals('en');
      check(trusted.translation!.text).equals('Translation');
      check(
        trusted.translation!.sourceId,
      ).equals('quran.com:sahih-international');
      check(trusted.shortExplanation!.text).equals('Explanation');
    });

    test('unreviewed and weak content never crosses the boundary', () {
      final unreviewed = validator.validate(
        model: _quranModel(
          reviewMetadata: _reviewMetadata(sourceValidationComplete: false),
        ),
        locale: 'ar',
        capability: DailyGuidanceCapability.display,
      );
      final weakHadith = validator.validate(
        model: _hadithModel(grading: HadithGrading.daif),
        locale: 'ar',
        capability: DailyGuidanceCapability.display,
      );

      check(unreviewed).isNull();
      check(weakHadith).isNull();
    });

    test('capability approvals are enforced independently', () {
      final model = _quranModel(
        reviewMetadata: _reviewMetadata(
          approvedForNotification: false,
          approvedForSharing: false,
        ),
      );

      check(
        validator.validate(
          model: model,
          locale: 'ar',
          capability: DailyGuidanceCapability.display,
        ),
      ).isNotNull();
      check(
        validator.validate(
          model: model,
          locale: 'ar',
          capability: DailyGuidanceCapability.notification,
        ),
      ).isNull();
      check(
        validator.validate(
          model: model,
          locale: 'ar',
          capability: DailyGuidanceCapability.share,
        ),
      ).isNull();
    });

    test('missing locale translation excludes English display', () {
      final trusted = validator.validate(
        model: _quranModel(translations: const {}),
        locale: 'en',
        capability: DailyGuidanceCapability.display,
      );

      check(trusted).isNull();
    });

    test('localized text without stable provenance is excluded', () {
      final trusted = validator.validate(
        model: _quranModel(includeTranslationSource: false),
        locale: 'en',
        capability: DailyGuidanceCapability.display,
      );

      check(trusted).isNull();
    });

    test('unapproved localized provenance is excluded', () {
      final trusted = validator.validate(
        model: _quranModel(translationSourceId: 'unknown:source'),
        locale: 'en',
        capability: DailyGuidanceCapability.display,
      );

      check(trusted).isNull();
    });

    test('mismatched source type never crosses the boundary', () {
      final trusted = validator.validate(
        model: _quranModel(includeQuranSource: false),
        locale: 'ar',
        capability: DailyGuidanceCapability.display,
      );

      check(trusted).isNull();
    });

    test('modified Quran text never crosses the boundary', () {
      final trusted = validator.validate(
        model: _quranModel(originalArabicText: 'فاذكروني أذكركم'),
        locale: 'ar',
        capability: DailyGuidanceCapability.display,
      );

      check(trusted).isNull();
    });

    test('unstable Hadith identity or authority never crosses boundary', () {
      for (final model in [
        _hadithModel(id: 'hadith_bukhari_wrong'),
        _hadithModel(gradingAuthority: 'Unknown'),
      ]) {
        check(
          validator.validate(
            model: model,
            locale: 'ar',
            capability: DailyGuidanceCapability.display,
          ),
        ).isNull();
      }
    });
  });
}

DailyGuidanceItemModel _quranModel({
  ContentReviewMetadataModel? reviewMetadata,
  Map<String, String>? translations = const {'en': 'Translation'},
  bool includeQuranSource = true,
  String originalArabicText =
      'فَٱذۡكُرُونِيٓ أَذۡكُرۡكُمۡ وَٱشۡكُرُواْ لِي وَلَا تَكۡفُرُونِ',
  bool includeTranslationSource = true,
  String translationSourceId = 'quran.com:sahih-international',
}) {
  return DailyGuidanceItemModel(
    id: 'quran_002_152',
    type: DailyGuidanceItemType.quran,
    status: ContentPublicationStatus.published,
    originalArabicText: originalArabicText,
    notificationExcerpt: 'فَٱذۡكُرُونِيٓ أَذۡكُرۡكُمۡ',
    shortExplanation: const {'ar': 'شرح عربي', 'en': 'Explanation'},
    translations: translations,
    shortExplanationSourceIds: const {
      'ar': 'tilawa:editorial:v1',
      'en': 'tilawa:editorial:v1',
    },
    translationSourceIds: includeTranslationSource
        ? {'en': translationSourceId}
        : null,
    topicTags: const ['remembrance'],
    availableLocales: const ['ar', 'en'],
    revision: 1,
    quranSource: includeQuranSource
        ? const QuranSourceMetadataModel(
            surahNumber: 2,
            surahNameArabic: 'البقرة',
            ayahStart: 152,
            quranTextSourceId: 'uthmani_hafs',
          )
        : null,
    reviewMetadata: reviewMetadata ?? _reviewMetadata(),
  );
}

DailyGuidanceItemModel _hadithModel({
  HadithGrading grading = HadithGrading.sahih,
  String id = 'hadith_bukhari_6412',
  String gradingAuthority = 'Al-Bukhari',
}) {
  return DailyGuidanceItemModel(
    id: id,
    type: DailyGuidanceItemType.hadith,
    status: ContentPublicationStatus.published,
    originalArabicText: 'نعمتان مغبون فيهما كثير من الناس',
    notificationExcerpt: 'نعمتان مغبون فيهما كثير من الناس',
    shortExplanation: const {'ar': 'شرح عربي', 'en': 'Explanation'},
    translations: const {'en': 'Translation'},
    shortExplanationSourceIds: const {
      'ar': 'tilawa:editorial:v1',
      'en': 'tilawa:editorial:v1',
    },
    translationSourceIds: const {'en': 'translation:test'},
    topicTags: const ['gratitude'],
    availableLocales: const ['ar', 'en'],
    revision: 1,
    hadithSource: HadithSourceMetadataModel(
      collection: 'Sahih al-Bukhari',
      referenceNumber: '6412',
      grading: grading,
      gradingAuthority: gradingAuthority,
    ),
    reviewMetadata: _reviewMetadata(),
  );
}

ContentReviewMetadataModel _reviewMetadata({
  bool sourceValidationComplete = true,
  bool approvedForNotification = true,
  bool approvedForSharing = true,
}) {
  return ContentReviewMetadataModel(
    sourceValidationComplete: sourceValidationComplete,
    translationValidationComplete: true,
    approvedForNotification: approvedForNotification,
    approvedForSharing: approvedForSharing,
  );
}
