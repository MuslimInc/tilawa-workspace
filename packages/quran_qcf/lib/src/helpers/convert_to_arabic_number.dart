/// Converts a number (int or String) to its Arabic-Indic numeral representation.
///
/// Arabic-Indic numerals: ٠ ١ ٢ ٣ ٤ ٥ ٦ ٧ ٨ ٩
///
/// Example:
/// ```dart
/// convertToArabicNumber(123);   // Returns '١٢٣'
/// convertToArabicNumber('456'); // Returns '٤٥٦'
/// convertToArabicNumber(0);     // Returns '٠'
/// ```
String convertToArabicNumber(String number) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  final numberString = number;

  final buffer = StringBuffer();
  for (var i = 0; i < numberString.length; i++) {
    final String char = numberString[i];
    final int? digit = int.tryParse(char);
    if (digit != null && digit >= 0 && digit <= 9) {
      buffer.write(arabicDigits[digit]);
    } else {
      // Keep non-digit characters as-is (e.g., negative sign, decimal point)
      buffer.write(char);
    }
  }

  return buffer.toString();
}
