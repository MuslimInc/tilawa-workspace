import '../../domain/entities/sadaqah_jariyah_config.dart';

SadaqahJariyahConfig mapSadaqahJariyahConfig(Map<String, dynamic>? data) {
  if (data == null) {
    return const SadaqahJariyahConfig();
  }
  return SadaqahJariyahConfig(
    featureTitleAr: _stringOr(
      data['featureTitleAr'],
      SadaqahJariyahConfig.defaultTitleAr,
    ),
    featureTitleEn: _stringOr(
      data['featureTitleEn'],
      SadaqahJariyahConfig.defaultTitleEn,
    ),
    featureSubtitleAr: _stringOr(
      data['featureSubtitleAr'],
      SadaqahJariyahConfig.defaultSubtitleAr,
    ),
    featureSubtitleEn: _stringOr(
      data['featureSubtitleEn'],
      SadaqahJariyahConfig.defaultSubtitleEn,
    ),
    whatsappE164: _stringOr(
      data['whatsappE164'],
      SadaqahJariyahConfig.defaultWhatsappE164,
    ),
    messageTemplateAr: _stringOr(
      data['messageTemplateAr'],
      SadaqahJariyahConfig.defaultMessageTemplateAr,
    ),
    messageTemplateEn: _stringOr(
      data['messageTemplateEn'],
      SadaqahJariyahConfig.defaultMessageTemplateEn,
    ),
    featureEnabled: data['featureEnabled'] != false,
  );
}

String _stringOr(Object? value, String fallback) {
  if (value is String) {
    return value;
  }
  return fallback;
}
