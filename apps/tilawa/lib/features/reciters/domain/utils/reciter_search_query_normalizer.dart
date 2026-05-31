/// Normalizes reciter search input for forgiving Arabic and Latin matching.
abstract final class ReciterSearchQueryNormalizer {
  static String normalize(String input) {
    var value = input.trim().toLowerCase();
    if (value.isEmpty) {
      return value;
    }

    value = _normalizeDigits(value);
    value = _removeDiacritics(value);
    value = value.replaceAll('\u0640', ''); // tatweel
    value = _normalizeArabicLetters(value);
    return value;
  }

  static bool matches({
    required String query,
    required String reciterName,
    required String reciterLetter,
  }) {
    final String normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final String name = normalize(reciterName);
    final String letter = normalize(reciterLetter);
    return name.contains(normalizedQuery) || letter.contains(normalizedQuery);
  }

  static String _normalizeDigits(String value) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const easternDigits = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final int codeUnit in value.codeUnits) {
      final String char = String.fromCharCode(codeUnit);
      final int arabicIndex = arabicDigits.indexOf(char);
      if (arabicIndex >= 0) {
        buffer.write(arabicIndex);
        continue;
      }
      final int easternIndex = easternDigits.indexOf(char);
      if (easternIndex >= 0) {
        buffer.write(easternIndex);
        continue;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  static String _removeDiacritics(String value) {
    return value.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
      '',
    );
  }

  static String _normalizeArabicLetters(String value) {
    return value
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll(RegExp(r'[ى]'), 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
  }
}
