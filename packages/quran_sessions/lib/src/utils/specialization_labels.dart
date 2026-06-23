/// Maps machine-readable specialization codes to human-readable Arabic labels.
abstract final class SpecializationLabels {
  static const Map<String, String> _ar = {
    'tajweed': 'تجويد',
    'recitation': 'تلاوة',
    'hifz': 'حفظ',
    'review': 'مراجعة',
    'children': 'تعليم الأطفال',
    'qaida': 'القاعدة النورانية',
    'tafsir': 'تفسير',
    'arabic': 'اللغة العربية',
  };

  static const Map<String, String> _en = {
    'tajweed': 'Tajweed',
    'recitation': 'Recitation',
    'hifz': 'Memorisation',
    'review': 'Review',
    'children': 'Children',
    'qaida': 'Qaida',
    'tafsir': 'Tafsir',
    'arabic': 'Arabic',
  };

  /// Returns the Arabic label for [code], falling back to the English label,
  /// and finally to [code] itself when no mapping exists.
  static String arabic(String code) => _ar[code] ?? english(code);

  static String english(String code) => _en[code] ?? code;
}
