/// Normalizes and validates phone numbers to E.164 format, accepting both
/// local and international input.
///
/// Rules per country:
/// - If the input already starts with `+`, it must be valid E.164 and its
///   dial prefix must match the selected [countryCode].
/// - If the input starts with a local leading `0`, strip the `0` and prepend
///   the country dial code. Example (Egypt): `01060099009` → `+201060099009`.
/// - Whitespace, hyphens, and parentheses are stripped before processing.
/// - After normalization the number is checked against country-specific length
///   rules so that, e.g., an Egyptian number is rejected when UAE is selected.
///
/// **This class has no Flutter dependencies and is fully unit-testable.**
abstract final class PhoneNormalizer {
  static const Map<String, String> _dialCodes = {
    'SA': '+966',
    'EG': '+20',
    'AE': '+971',
    'KW': '+965',
    'QA': '+974',
    'BH': '+973',
    'OM': '+968',
    'JO': '+962',
    'GB': '+44',
    'US': '+1',
    'CA': '+1',
    'PK': '+92',
    'IN': '+91',
    'MY': '+60',
    'TR': '+90',
  };

  /// Countries where local numbers start with a leading `0` that must be
  /// stripped before prepending the dial code.
  static const Set<String> _stripLeadingZero = {
    'EG', // 0XXXXXXXXXX → +20XXXXXXXXXX
    'SA', // 05XXXXXXXXX → +9665XXXXXXXX
    'AE', // 05XXXXXXXXX → +9715XXXXXXXX
    'GB', // 07XXXXXXXXX → +447XXXXXXXXX
    'TR', // 05XXXXXXXXX → +905XXXXXXXXX
    'JO', // 07XXXXXXXX  → +9627XXXXXXXX
    'PK', // 03XXXXXXXXX → +923XXXXXXXXX
    'IN', // 0XXXXXXXXXX → +91XXXXXXXXXX (less common)
    'MY', // 01X-XXXXXXX → +601X-XXXXXXX
  };

  /// Country-specific expected digit count after the dial code.
  /// Used to reject numbers that normalise to E.164 but belong to
  /// a different country (e.g. an Egyptian number with UAE selected).
  static const Map<String, (int min, int max)> _localDigits = {
    'EG': (10, 10), // +20 + 10 digits
    'SA': (9, 9), // +966 + 9 digits
    'AE': (9, 9), // +971 + 9 digits
    'KW': (8, 8), // +965 + 8 digits
    'QA': (8, 8), // +974 + 8 digits
    'BH': (8, 8), // +973 + 8 digits
    'OM': (8, 8), // +968 + 8 digits
    'JO': (9, 9), // +962 + 9 digits
    'GB': (10, 11), // +44 + 10–11 digits
    'US': (10, 10), // +1 + 10 digits
    'CA': (10, 10), // +1 + 10 digits
    'PK': (10, 10), // +92 + 10 digits
    'IN': (10, 10), // +91 + 10 digits
    'MY': (9, 10), // +60 + 9–10 digits
    'TR': (10, 10), // +90 + 10 digits
  };

  /// Country-specific required prefixes for the local part (digits after dial code).
  /// Any entry here restricts valid numbers to those whose local part starts
  /// with one of the listed strings.  Countries not in this map are not prefix-
  /// restricted (only length is checked).
  static const Map<String, List<String>> _localStartsWith = {
    'EG': ['10', '11', '12', '15'], // 010x, 011x, 012x, 015x
    'SA': ['5'], // 05x
    'AE': ['5'], // 05x
    'KW': ['5', '6', '9'], // 5x, 6x, 9x
    'QA': ['3', '4', '5', '6', '7'],
    'BH': ['3'],
    'OM': ['7', '9'],
    'JO': ['7', '6'],
    'GB': ['7', '1', '2', '3'],
    'TR': ['5'], // 05x
    'PK': ['3'], // 03x
    'IN': ['6', '7', '8', '9'],
    'MY': ['1'], // 01x
  };

  static final _e164 = RegExp(r'^\+[1-9]\d{7,14}$');
  static final _whitespace = RegExp(r'[\s\-\(\)]');

  /// Normalizes [raw] to E.164 using [countryCode].
  ///
  /// Returns the normalized E.164 string on success, or `null` when the
  /// input is invalid or does not match [countryCode].
  static String? normalize(String raw, String countryCode) {
    final cleaned = raw.trim().replaceAll(_whitespace, '');
    if (cleaned.isEmpty) return null;

    // Already international format — validate format then country match.
    if (cleaned.startsWith('+')) {
      if (!_e164.hasMatch(cleaned)) return null;
      return _matchesCountry(cleaned, countryCode) ? cleaned : null;
    }

    final dc = _dialCodes[countryCode];
    if (dc == null) return null;

    var local = cleaned;
    if (_stripLeadingZero.contains(countryCode) && local.startsWith('0')) {
      local = local.substring(1);
    }

    final candidate = '$dc$local';
    if (!_e164.hasMatch(candidate)) return null;
    return _matchesCountry(candidate, countryCode) ? candidate : null;
  }

  /// Returns `true` when [raw] (given [countryCode]) normalises to a valid
  /// E.164 number that belongs to [countryCode].
  static bool isValid(String raw, String countryCode) =>
      normalize(raw, countryCode) != null;

  /// Detailed validation result — use when you need to distinguish a format
  /// error from a country mismatch (e.g. Egyptian number entered for UAE).
  static PhoneValidationResult validate(String raw, String countryCode) {
    final cleaned = raw.trim().replaceAll(_whitespace, '');
    if (cleaned.isEmpty) return PhoneValidationResult.invalid;

    // International input: check format first, then country.
    if (cleaned.startsWith('+')) {
      if (!_e164.hasMatch(cleaned)) return PhoneValidationResult.invalid;
      return _matchesCountry(cleaned, countryCode)
          ? PhoneValidationResult.valid
          : PhoneValidationResult.countryMismatch;
    }

    // Local input: try to normalise; if it fails the length/prefix check the
    // number is structurally wrong for this country.
    final dc = _dialCodes[countryCode];
    if (dc == null) return PhoneValidationResult.invalid;

    var local = cleaned;
    if (_stripLeadingZero.contains(countryCode) && local.startsWith('0')) {
      local = local.substring(1);
    }

    final candidate = '$dc$local';
    if (!_e164.hasMatch(candidate)) return PhoneValidationResult.invalid;

    if (_matchesCountry(candidate, countryCode)) {
      return PhoneValidationResult.valid;
    }

    // If the local part already starts with a known prefix for the selected
    // country, the user is typing a local number for this country that is just
    // too short or too long — return invalid, not countryMismatch.  Without this
    // guard a 10-digit Egyptian "010…" would be mis-identified as Malaysian
    // because the 9 stripped digits happen to normalise to a valid MY number.
    final selectedPrefixes = _localStartsWith[countryCode];
    if (selectedPrefixes != null &&
        selectedPrefixes.any((p) => local.startsWith(p))) {
      return PhoneValidationResult.invalid;
    }

    // Local input may still indicate a different country when it begins with
    // a national leading zero and the selected country does not use one.
    final isOtherCountry =
        cleaned.startsWith('0') &&
        _looksLikeOtherCountryLocal(cleaned, countryCode);
    return isOtherCountry
        ? PhoneValidationResult.countryMismatch
        : PhoneValidationResult.invalid;
  }

  static bool _looksLikeOtherCountryLocal(
    String cleaned,
    String selectedCountry,
  ) {
    for (final country in _stripLeadingZero) {
      if (country == selectedCountry) continue;
      if (normalize(cleaned, country) != null) {
        return true;
      }
    }
    return false;
  }

  /// Returns the dial code for [countryCode], e.g. `'+20'` for `'EG'`.
  /// Returns an empty string for unknown codes.
  static String dialCode(String countryCode) => _dialCodes[countryCode] ?? '';

  /// Short placeholder shown inside the text field (local format only).
  static String hint(String countryCode) => switch (countryCode) {
    'EG' => '01012345678',
    'SA' => '0501234567',
    'AE' => '0501234567',
    'KW' => '65012345',
    'QA' => '33012345',
    'BH' => '33012345',
    'OM' => '92012345',
    'JO' => '0791234567',
    'GB' => '07911123456',
    'US' || 'CA' => '2015551234',
    'PK' => '03001234567',
    'IN' => '9876543210',
    'MY' => '0123456789',
    'TR' => '05301234567',
    _ => 'XXXXXXXXX',
  };

  /// Two-format example shown as helper text below the field.
  /// Uses `/` as separator (pure ASCII, direction-neutral).
  static String formatGuide(String countryCode) => switch (countryCode) {
    'EG' => '01012345678  /  +201012345678',
    'SA' => '0501234567  /  +966501234567',
    'AE' => '0501234567  /  +971501234567',
    'KW' => '65012345  /  +96565012345',
    'QA' => '33012345  /  +97433012345',
    'BH' => '33012345  /  +97333012345',
    'OM' => '92012345  /  +96892012345',
    'JO' => '0791234567  /  +962791234567',
    'GB' => '07911123456  /  +447911123456',
    'US' || 'CA' => '2015551234  /  +12015551234',
    'PK' => '03001234567  /  +923001234567',
    'IN' => '9876543210  /  +919876543210',
    'MY' => '0123456789  /  +60123456789',
    'TR' => '05301234567  /  +905301234567',
    _ => '${dialCode(countryCode)}XXXXXXXXX',
  };

  // ── Private ───────────────────────────────────────────────────────────────

  /// Returns `true` when [e164] starts with [countryCode]'s dial prefix,
  /// the local-part digit count is within the expected range, and the local
  /// part begins with an allowed prefix (where defined).
  static bool _matchesCountry(String e164, String countryCode) {
    final dc = _dialCodes[countryCode];
    if (dc == null) return false;
    if (!e164.startsWith(dc)) return false;

    final (minLen, maxLen) = _localDigits[countryCode]!;
    final localPart = e164.substring(dc.length); // digits after dial code
    final localLen = localPart.length;
    if (localLen < minLen || localLen > maxLen) return false;

    final prefixes = _localStartsWith[countryCode];
    if (prefixes != null) {
      if (!prefixes.any(localPart.startsWith)) return false;
    }
    return true;
  }
}

/// Result of [PhoneNormalizer.validate].
enum PhoneValidationResult {
  /// Input normalises to a valid E.164 number that belongs to the selected country.
  valid,

  /// Input is malformed and cannot be interpreted as any phone number.
  invalid,

  /// Input is a structurally valid phone number but does not belong to
  /// the selected country (e.g. Egyptian `010…` entered while UAE is selected).
  countryMismatch,
}
