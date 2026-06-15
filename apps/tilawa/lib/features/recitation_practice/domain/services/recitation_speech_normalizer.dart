import 'package:quran_qcf/quran_qcf.dart';

/// Normalizes Quranic and speech text so tashkeel-free ASR can be compared.
class RecitationSpeechNormalizer {
  const RecitationSpeechNormalizer(this._textNormalizer);

  final TextNormalizationService _textNormalizer;

  static final RegExp _formatCharacters = RegExp(r'[\u200C-\u200F\uFEFF\u061C]');
  static final RegExp _speechPunctuation = RegExp(
    r'[،؛؟!.,"«»٪٫٬\-–—:؛]',
  );
  static final RegExp _arabicLetters = RegExp(r'[\u0600-\u06FF]');
  static final RegExp _latinLetters = RegExp(r'[A-Za-z]');
  static final RegExp _arabicRuns = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+',
  );

  static const Map<String, String> _speechReplacements = <String, String>{
    '\u0671': '\u0627', // Alef wasla
    '\uFDF2': 'الله', // Allah ligature
    '\u06CC': '\u0649', // Farsi yeh
  };

  /// Keeps Arabic script and drops Latin noise from ASR when locale is wrong.
  String sanitizeSpokenTranscript(String input) {
    var prepared = input;
    for (final MapEntry<String, String> entry
        in _speechReplacements.entries) {
      prepared = prepared.replaceAll(entry.key, entry.value);
    }

    final String arabicOnly = _extractArabicRuns(prepared);
    if (!_isUsableArabicTranscript(arabicOnly)) {
      return '';
    }
    return normalize(arabicOnly);
  }

  String normalize(String input) {
    var result = _textNormalizer.normalise(input);
    result = _textNormalizer.removeDiacritics(result);

    for (final MapEntry<String, String> entry
        in _speechReplacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    result = result.replaceAll(_formatCharacters, '');
    result = result.replaceAll(_speechPunctuation, ' ');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    return result;
  }

  bool _isUsableArabicTranscript(String input) {
    final int arabicCount = _arabicLetters.allMatches(input).length;
    if (arabicCount == 0) {
      return false;
    }
    final int latinCount = _latinLetters.allMatches(input).length;
    return arabicCount >= latinCount;
  }

  String _extractArabicRuns(String input) {
    final Iterable<RegExpMatch> matches = _arabicRuns.allMatches(input);
    return matches.map((RegExpMatch match) => match.group(0)!).join(' ');
  }
}
