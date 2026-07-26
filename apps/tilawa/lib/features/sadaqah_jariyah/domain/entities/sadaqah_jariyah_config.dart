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
    this.whatsappE164 = '',
    this.messageTemplateAr = defaultMessageTemplateAr,
    this.messageTemplateEn = defaultMessageTemplateEn,
    this.featureEnabled = true,
  });

  static const String defaultTitleAr = 'صدقة جارية';
  static const String defaultTitleEn = 'Sadaqah Jariyah';
  static const String defaultSubtitleAr = 'نيات دعم';
  static const String defaultSubtitleEn = 'Dedications of intention';

  static const String defaultMessageTemplateEn =
      'Assalamu alaikum,\n'
      'I want to support MeMuslim as Sadaqah Jariyah.\n\n'
      'Deceased name:\n'
      'Relation (optional):\n'
      'Support amount / proof:\n\n'
      'I intend this support as an ongoing charity for the deceased, '
      'and I ask Allah to accept it.';

  static const String defaultMessageTemplateAr =
      'السلام عليكم،\n'
      'أريد دعم أنا مسلم كصدقة جارية.\n\n'
      'اسم المتوفى:\n'
      'صلة القرابة (اختياري):\n'
      'مبلغ الدعم / إثبات:\n\n'
      'أنوي هذا الدعم صدقة جارية عن المتوفى، وأسأل الله القبول.';

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
