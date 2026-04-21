import 'interfaces/text_normalization_service.dart';

/// Implementation of [TextNormalizationService].
///
/// Follows Single Responsibility Principle - only handles text normalization.
class TextNormalizationServiceImpl implements TextNormalizationService {
  const TextNormalizationServiceImpl();

  /// Characters to remove for normalization (Koranic annotations, tashkeel, etc.)
  static const List<String> _charsToRemove = [
    '\u0610', // ARABIC SIGN SALLALLAHOU ALAYHE WA SALLAM
    '\u0611', // ARABIC SIGN ALAYHE ASSALLAM
    '\u0612', // ARABIC SIGN RAHMATULLAH ALAYHE
    '\u0613', // ARABIC SIGN RADI ALLAHOU ANHU
    '\u0614', // ARABIC SIGN TAKHALLUS
    '\u0615', // ARABIC SMALL HIGH TAH
    '\u0616', // ARABIC SMALL HIGH LIGATURE ALEF WITH LAM WITH YEH
    '\u0617', // ARABIC SMALL HIGH ZAIN
    '\u0618', // ARABIC SMALL FATHA
    '\u0619', // ARABIC SMALL DAMMA
    '\u061A', // ARABIC SMALL KASRA
    '\u06D6', // ARABIC SMALL HIGH LIGATURE SAD WITH LAM WITH ALEF MAKSURA
    '\u06D7', // ARABIC SMALL HIGH LIGATURE QAF WITH LAM WITH ALEF MAKSURA
    '\u06D8', // ARABIC SMALL HIGH MEEM INITIAL FORM
    '\u06D9', // ARABIC SMALL HIGH LAM ALEF
    '\u06DA', // ARABIC SMALL HIGH JEEM
    '\u06DB', // ARABIC SMALL HIGH THREE DOTS
    '\u06DC', // ARABIC SMALL HIGH SEEN
    '\u06DD', // ARABIC END OF AYAH
    '\u06DE', // ARABIC START OF RUB EL HIZB
    '\u06DF', // ARABIC SMALL HIGH ROUNDED ZERO
    '\u06E0', // ARABIC SMALL HIGH UPRIGHT RECTANGULAR ZERO
    '\u06E1', // ARABIC SMALL HIGH DOTLESS HEAD OF KHAH
    '\u06E2', // ARABIC SMALL HIGH MEEM ISOLATED FORM
    '\u06E3', // ARABIC SMALL LOW SEEN
    '\u06E4', // ARABIC SMALL HIGH MADDA
    '\u06E5', // ARABIC SMALL WAW
    '\u06E6', // ARABIC SMALL YEH
    '\u06E7', // ARABIC SMALL HIGH YEH
    '\u06E8', // ARABIC SMALL HIGH NOON
    '\u06E9', // ARABIC PLACE OF SAJDAH
    '\u06EA', // ARABIC EMPTY CENTRE LOW STOP
    '\u06EB', // ARABIC EMPTY CENTRE HIGH STOP
    '\u06EC', // ARABIC ROUNDED HIGH STOP WITH FILLED CENTRE
    '\u06ED', // ARABIC SMALL LOW MEEM
    '\u0640', // TATWEEL
    '\u064B', // ARABIC FATHATAN
    '\u064C', // ARABIC DAMMATAN
    '\u064D', // ARABIC KASRATAN
    '\u064E', // ARABIC FATHA
    '\u064F', // ARABIC DAMMA
    '\u0650', // ARABIC KASRA
    '\u0651', // ARABIC SHADDA
    '\u0652', // ARABIC SUKUN
    '\u0653', // ARABIC MADDAH ABOVE
    '\u0654', // ARABIC HAMZA ABOVE
    '\u0655', // ARABIC HAMZA BELOW
    '\u0656', // ARABIC SUBSCRIPT ALEF
    '\u0657', // ARABIC INVERTED DAMMA
    '\u0658', // ARABIC MARK NOON GHUNNA
    '\u0659', // ARABIC ZWARAKAY
    '\u065A', // ARABIC VOWEL SIGN SMALL V ABOVE
    '\u065B', // ARABIC VOWEL SIGN INVERTED SMALL V ABOVE
    '\u065C', // ARABIC VOWEL SIGN DOT BELOW
    '\u065D', // ARABIC REVERSED DAMMA
    '\u065E', // ARABIC FATHA WITH TWO DOTS
    '\u065F', // ARABIC WAVY HAMZA BELOW
    '\u0670', // ARABIC LETTER SUPERSCRIPT ALEF
  ];

  /// Character replacements for normalization.
  static const Map<String, String> _charReplacements = {
    '\u0624': '\u0648', // Waw Hamza Above -> Waw
    '\u0629': '\u0647', // Ta Marbuta -> Ha
    '\u064A': '\u0649', // Ya -> Alif Maksura
    '\u0626': '\u0649', // Ya Hamza Above -> Alif Maksura
    '\u0622': '\u0627', // Alif with Madda Above -> Alif
    '\u0623': '\u0627', // Alif with Hamza Above -> Alif
    '\u0625': '\u0627', // Alif with Hamza Below -> Alif
  };

  /// Diacritics pattern for removal.
  static final RegExp _diacriticsPattern = RegExp(
    '[${[
      '\u064E', // Fatha
      '\u064F', // Damma
      '\u0650', // Kasra
      '\u0651', // Shadda
      '\u064B', // Tanwin Fatha
      '\u064C', // Tanwin Damma
      '\u064D', // Tanwin Kasra
    ].map(RegExp.escape).join()}]',
  );

  @override
  String normalise(String input) {
    var result = input;

    // Remove characters
    for (final String char in _charsToRemove) {
      result = result.replaceAll(char, '');
    }

    // Replace characters
    for (final MapEntry<String, String> entry in _charReplacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result;
  }

  @override
  String removeDiacritics(String input) {
    return input.replaceAll(_diacriticsPattern, '');
  }
}
