import 'package:quran_qcf/quran_qcf.dart';

import '../../domain/entities/daily_guidance_enums.dart';
import '../../domain/entities/daily_guidance_item.dart';
import '../../domain/entities/daily_guidance_locale.dart';
import '../models/daily_guidance_item_model.dart';
import '../models/content_review_metadata_model.dart';
import '../models/hadith_source_metadata_model.dart';
import '../models/quran_source_metadata_model.dart';

/// The only Data-to-Domain trust boundary for Daily Guidance content.
class DailyGuidanceContentValidator {
  const DailyGuidanceContentValidator();

  DailyGuidanceItem? validate({
    required DailyGuidanceItemModel model,
    required String locale,
    required DailyGuidanceCapability capability,
  }) {
    final normalizedLocale = DailyGuidanceLocale.parse(locale)?.name;
    if (normalizedLocale == null ||
        !_hasValidCommonMetadata(model, normalizedLocale, capability) ||
        !_hasValidSource(model)) {
      return null;
    }

    return DailyGuidanceItem(
      id: model.id,
      type: model.type,
      status: model.status,
      originalArabicText: model.originalArabicText,
      notificationExcerpt: model.notificationExcerpt,
      shortExplanation: _localizedContent(
        texts: model.shortExplanation,
        sourceIds: model.shortExplanationSourceIds,
        locale: normalizedLocale,
      ),
      translation: normalizedLocale == 'ar'
          ? null
          : _localizedContent(
              texts: model.translations,
              sourceIds: model.translationSourceIds,
              locale: normalizedLocale,
            ),
      topicTags: model.topicTags,
      occasionTags: model.occasionTags,
      availableLocales: model.availableLocales,
      validFrom: model.validFrom,
      validUntil: model.validUntil,
      publishedAt: model.publishedAt,
      retiredAt: model.retiredAt,
      revision: model.revision,
      quranSource: model.quranSource?.toEntity(),
      hadithSource: _hadithSource(model, normalizedLocale),
      reviewMetadata: model.reviewMetadata.toEntity(),
    );
  }

  bool _hasValidCommonMetadata(
    DailyGuidanceItemModel model,
    String locale,
    DailyGuidanceCapability capability,
  ) {
    final review = model.reviewMetadata;
    if (model.id.trim().isEmpty ||
        model.status != ContentPublicationStatus.published ||
        model.originalArabicText.trim().isEmpty ||
        model.revision < 1 ||
        !model.availableLocales.contains(locale) ||
        !review.sourceValidationComplete) {
      return false;
    }
    if (locale != 'ar' &&
        (!review.translationValidationComplete ||
            !_hasLocalizedProvenance(
              model.translations,
              model.translationSourceIds,
              locale,
            ))) {
      return false;
    }
    if (model.shortExplanation?.containsKey(locale) ?? false) {
      if (!_hasLocalizedProvenance(
        model.shortExplanation,
        model.shortExplanationSourceIds,
        locale,
      )) {
        return false;
      }
      if (model.shortExplanationSourceIds?[locale] != 'tilawa:editorial:v1') {
        return false;
      }
    }
    if (locale != 'ar' &&
        model.translationSourceIds?[locale] !=
            _expectedTranslationSourceId(model)) {
      return false;
    }
    return switch (capability) {
      DailyGuidanceCapability.display => true,
      DailyGuidanceCapability.notification =>
        review.approvedForNotification &&
            !(model.notificationExcerpt?.trim().isEmpty ?? true),
      DailyGuidanceCapability.share => review.approvedForSharing,
    };
  }

  bool _hasValidSource(DailyGuidanceItemModel model) {
    return switch (model.type) {
      DailyGuidanceItemType.quran =>
        model.hadithSource == null &&
            model.quranSource != null &&
            model.quranSource!.surahNumber >= 1 &&
            model.quranSource!.surahNumber <= 114 &&
            model.quranSource!.surahNameArabic.trim().isNotEmpty &&
            model.quranSource!.ayahStart >= 1 &&
            (model.quranSource!.ayahEnd == null ||
                model.quranSource!.ayahEnd! >= model.quranSource!.ayahStart) &&
            model.quranSource!.quranTextSourceId == 'uthmani_hafs' &&
            _hasCanonicalQuranText(model),
      DailyGuidanceItemType.hadith =>
        model.quranSource == null &&
            model.hadithSource != null &&
            model.hadithSource!.grading == HadithGrading.sahih &&
            _supportedHadithCollections.containsKey(
              model.hadithSource!.collection,
            ) &&
            model.hadithSource!.referenceNumber.trim().isNotEmpty &&
            model.hadithSource!.gradingAuthority ==
                _gradingAuthorityFor(model.hadithSource!.collection) &&
            model.id == _hadithId(model.hadithSource!),
    };
  }

  bool _hasCanonicalQuranText(DailyGuidanceItemModel model) {
    final source = model.quranSource!;
    final ayahEnd = source.ayahEnd ?? source.ayahStart;
    try {
      final canonicalText = [
        for (var ayah = source.ayahStart; ayah <= ayahEnd; ayah++)
          const VerseServiceImpl().getVerse(
            source.surahNumber,
            ayah,
            verseEndSymbol: false,
          ),
      ].join(' ');
      return model.originalArabicText == canonicalText &&
          model.id ==
              _quranId(source.surahNumber, source.ayahStart, source.ayahEnd);
    } on QuranException {
      return false;
    }
  }

  String _quranId(int surah, int start, int? end) {
    final prefix =
        'quran_${surah.toString().padLeft(3, '0')}_'
        '${start.toString().padLeft(3, '0')}';
    return end == null ? prefix : '${prefix}_${end.toString().padLeft(3, '0')}';
  }

  String _hadithId(HadithSourceMetadataModel source) {
    final collection = source.collection == 'Sahih al-Bukhari'
        ? 'bukhari'
        : 'muslim';
    return 'hadith_${collection}_${source.referenceNumber}';
  }

  String _gradingAuthorityFor(String collection) {
    return collection == 'Sahih al-Bukhari' ? 'Al-Bukhari' : 'Muslim';
  }

  String _expectedTranslationSourceId(DailyGuidanceItemModel model) {
    if (model.type == DailyGuidanceItemType.hadith) {
      final source = model.hadithSource!;
      final collection = source.collection == 'Sahih al-Bukhari'
          ? 'bukhari'
          : 'muslim';
      return 'sunnah.com:$collection:${source.referenceNumber}';
    }
    return model.id == 'quran_002_152'
        ? 'quran.com:sahih-international'
        : 'quran.com:clear-quran';
  }

  bool _hasLocalizedProvenance(
    Map<String, String>? texts,
    Map<String, String>? sourceIds,
    String locale,
  ) {
    return !(texts?[locale]?.trim().isEmpty ?? true) &&
        !(sourceIds?[locale]?.trim().isEmpty ?? true);
  }

  LocalizedGuidanceContent? _localizedContent({
    required Map<String, String>? texts,
    required Map<String, String>? sourceIds,
    required String locale,
  }) {
    if (!_hasLocalizedProvenance(texts, sourceIds, locale)) return null;
    return LocalizedGuidanceContent(
      locale: locale,
      text: texts![locale]!,
      sourceId: sourceIds![locale]!,
    );
  }

  HadithSourceMetadata? _hadithSource(
    DailyGuidanceItemModel model,
    String locale,
  ) {
    final source = model.hadithSource;
    if (source == null) return null;
    return HadithSourceMetadata(
      collection: locale == 'ar'
          ? _supportedHadithCollections[source.collection]!
          : source.collection,
      book: source.book,
      chapter: source.chapter,
      referenceNumber: source.referenceNumber,
      grading: source.grading,
      gradingAuthority: source.gradingAuthority,
      sourceEdition: source.sourceEdition,
    );
  }

  static const Map<String, String> _supportedHadithCollections = {
    'Sahih al-Bukhari': 'صحيح البخاري',
    'Sahih Muslim': 'صحيح مسلم',
  };
}
