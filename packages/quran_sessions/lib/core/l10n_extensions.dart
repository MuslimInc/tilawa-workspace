import 'package:flutter/widgets.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

import '../src/domain/entities/teacher_application.dart';

/// Provides easy access to Quran Sessions package-local localization.
extension QuranSessionsL10nX on BuildContext {
  QuranSessionsLocalizations get quranSessionsL10n =>
      QuranSessionsLocalizations.of(this);
}

/// Localized labels for codes that are stored as machine-readable values.
extension QuranSessionsLabelX on QuranSessionsLocalizations {
  String specializationLabel(String code) => switch (code) {
    'tajweed' => specialization_tajweed,
    'recitation' => specialization_recitation,
    'hifz' => specialization_hifz,
    'review' => specialization_review,
    'children' => specialization_children,
    'qaida' => specialization_qaida,
    'tafsir' => specialization_tafsir,
    'arabic' => specialization_arabic,
    _ => code,
  };

  String teachingLanguageLabel(String code) => switch (code) {
    'ar' => teachingLanguage_ar,
    'en' => teachingLanguage_en,
    'ur' => teachingLanguage_ur,
    'fr' => teachingLanguage_fr,
    'tr' => teachingLanguage_tr,
    'ms' => teachingLanguage_ms,
    _ => code,
  };

  String preferredContactMethodLabel(PreferredContactMethod method) =>
      switch (method) {
        PreferredContactMethod.whatsapp => contactWhatsapp,
        PreferredContactMethod.phone => contactPhone,
        PreferredContactMethod.email => contactEmail,
      };
}
