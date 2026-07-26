import 'package:equatable/equatable.dart';

/// Remote display + WhatsApp config for Sadaqah Jariyah.
///
/// Empty title/subtitle fields should fall back to bundled l10n in the UI.
class SadaqahJariyahConfig extends Equatable {
  const SadaqahJariyahConfig({
    this.featureTitleAr = defaultTitleAr,
    this.featureTitleEn = defaultTitleEn,
    this.featureSubtitleAr = defaultSubtitleAr,
    this.featureSubtitleEn = defaultSubtitleEn,
    this.whatsappE164 = defaultWhatsappE164,
    this.messageTemplateAr = defaultMessageTemplateAr,
    this.messageTemplateEn = defaultMessageTemplateEn,
    this.featureEnabled = true,
  });

  static const String defaultTitleAr = 'صدقة جارية';
  static const String defaultTitleEn = 'Sadaqah Jariyah';
  static const String defaultSubtitleAr = 'صدقة جارية';
  static const String defaultSubtitleEn = 'Sadaqah Jariyah';
  static const String defaultWhatsappE164 = '+201060099009';

  static const String defaultMessageTemplateEn =
      'Assalamu alaikum,\n'
      'I want to add a person to the Sadaqah Jariyah list in MeMuslim.\n\n'
      'Deceased name:\n'
      'Relation (optional):\n'
      'Short note (optional):\n\n'
      'Please add them to the list. May Allah accept.';

  static const String defaultMessageTemplateAr =
      'السلام عليكم،\n'
      'أريد إضافة اسم إلى قائمة الصدقة الجارية في أنا مسلم.\n\n'
      'اسم المتوفى:\n'
      'صلة القرابة (اختياري):\n'
      'ملاحظة قصيرة (اختياري):\n\n'
      'يرجى إضافتهم إلى القائمة. أسأل الله القبول.';

  final String featureTitleAr;
  final String featureTitleEn;
  final String featureSubtitleAr;
  final String featureSubtitleEn;
  final String whatsappE164;
  final String messageTemplateAr;
  final String messageTemplateEn;
  final bool featureEnabled;

  String titleForLanguageCode(String languageCode) {
    final String raw = languageCode.toLowerCase().startsWith('ar')
        ? featureTitleAr
        : featureTitleEn;
    if (raw.trim().isEmpty) {
      return languageCode.toLowerCase().startsWith('ar')
          ? defaultTitleAr
          : defaultTitleEn;
    }
    return raw.trim();
  }

  String subtitleForLanguageCode(String languageCode) {
    final String raw = languageCode.toLowerCase().startsWith('ar')
        ? featureSubtitleAr
        : featureSubtitleEn;
    if (raw.trim().isEmpty) {
      return languageCode.toLowerCase().startsWith('ar')
          ? defaultSubtitleAr
          : defaultSubtitleEn;
    }
    return raw.trim();
  }

  String messageTemplateForLanguageCode(String languageCode) {
    final String raw = languageCode.toLowerCase().startsWith('ar')
        ? messageTemplateAr
        : messageTemplateEn;
    if (raw.trim().isEmpty) {
      return languageCode.toLowerCase().startsWith('ar')
          ? defaultMessageTemplateAr
          : defaultMessageTemplateEn;
    }
    return raw;
  }

  @override
  List<Object?> get props => [
    featureTitleAr,
    featureTitleEn,
    featureSubtitleAr,
    featureSubtitleEn,
    whatsappE164,
    messageTemplateAr,
    messageTemplateEn,
    featureEnabled,
  ];
}
