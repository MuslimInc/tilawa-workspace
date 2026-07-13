/// Supported Daily Guidance content locales.
enum DailyGuidanceLocale {
  ar,
  en;

  static DailyGuidanceLocale? parse(String rawLocale) {
    final languageCode = rawLocale.trim().replaceAll('_', '-').split('-').first;
    return switch (languageCode.toLowerCase()) {
      'ar' => DailyGuidanceLocale.ar,
      'en' => DailyGuidanceLocale.en,
      _ => null,
    };
  }
}
