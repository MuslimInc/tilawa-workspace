import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/utils/phone_normalizer.dart';

void main() {
  group('PhoneNormalizer.normalize', () {
    group('Egypt (EG)', () {
      test('accepts local 010 and normalizes to E.164', () {
        check(
          PhoneNormalizer.normalize('01012345678', 'EG'),
        ).equals('+201012345678');
      });

      test('accepts local 011', () {
        check(
          PhoneNormalizer.normalize('01112345678', 'EG'),
        ).equals('+201112345678');
      });

      test('accepts local 012', () {
        check(
          PhoneNormalizer.normalize('01212345678', 'EG'),
        ).equals('+201212345678');
      });

      test('accepts local 015', () {
        check(
          PhoneNormalizer.normalize('01512345678', 'EG'),
        ).equals('+201512345678');
      });

      test('accepts local format starting with 010 (legacy test)', () {
        check(
          PhoneNormalizer.normalize('01060099009', 'EG'),
        ).equals('+201060099009');
      });

      test('accepts already-normalized E.164', () {
        check(
          PhoneNormalizer.normalize('+201012345678', 'EG'),
        ).equals('+201012345678');
      });

      test('strips whitespace before normalizing', () {
        check(
          PhoneNormalizer.normalize('010 600 99009', 'EG'),
        ).equals('+201060099009');
      });

      test('rejects number with invalid prefix (06x)', () {
        check(PhoneNormalizer.normalize('06012345678', 'EG')).isNull();
      });

      test('rejects partial number (too short)', () {
        check(PhoneNormalizer.normalize('0101234', 'EG')).isNull();
      });

      test('rejects partial number 65012345 (8 digits, not Egyptian)', () {
        check(PhoneNormalizer.normalize('65012345', 'EG')).isNull();
      });

      test('rejects 501234567 (9 digits, UAE-style local)', () {
        check(PhoneNormalizer.normalize('501234567', 'EG')).isNull();
      });

      test('rejects Egyptian number when UAE is selected', () {
        check(PhoneNormalizer.normalize('01012345678', 'AE')).isNull();
      });

      test('rejects E.164 Egyptian number when UAE is selected', () {
        check(PhoneNormalizer.normalize('+201060099009', 'AE')).isNull();
      });
    });

    group('Kuwait (KW)', () {
      test('accepts 65xxxxxx (starts with 6)', () {
        check(
          PhoneNormalizer.normalize('65012345', 'KW'),
        ).equals('+96565012345');
      });

      test('accepts 65123456', () {
        check(
          PhoneNormalizer.normalize('65123456', 'KW'),
        ).equals('+96565123456');
      });

      test('accepts 69999999', () {
        check(
          PhoneNormalizer.normalize('69999999', 'KW'),
        ).equals('+96569999999');
      });

      test('accepts 50xxxxxx (starts with 5)', () {
        check(
          PhoneNormalizer.normalize('50123456', 'KW'),
        ).equals('+96550123456');
      });

      test('accepts 90xxxxxx (starts with 9)', () {
        check(
          PhoneNormalizer.normalize('90123456', 'KW'),
        ).equals('+96590123456');
      });

      test('accepts E.164 +96565012345', () {
        check(
          PhoneNormalizer.normalize('+96565012345', 'KW'),
        ).equals('+96565012345');
      });

      test('rejects 01020030 — starts with 0, not a valid KW prefix', () {
        check(PhoneNormalizer.normalize('01020030', 'KW')).isNull();
      });

      test('rejects Egyptian 01012345678 when KW is selected', () {
        check(PhoneNormalizer.normalize('01012345678', 'KW')).isNull();
      });

      test('rejects Egyptian 01112345678 when KW is selected', () {
        check(PhoneNormalizer.normalize('01112345678', 'KW')).isNull();
      });

      test('rejects Egyptian E.164 +201012345678 for KW', () {
        check(PhoneNormalizer.normalize('+201012345678', 'KW')).isNull();
      });

      test('rejects partial number (too short)', () {
        check(PhoneNormalizer.normalize('6501', 'KW')).isNull();
      });
    });

    group('UAE (AE)', () {
      test('accepts 0501234567 and normalizes to E.164', () {
        check(
          PhoneNormalizer.normalize('0501234567', 'AE'),
        ).equals('+971501234567');
      });

      test('accepts 0521234567', () {
        check(
          PhoneNormalizer.normalize('0521234567', 'AE'),
        ).equals('+971521234567');
      });

      test('accepts 0541234567', () {
        check(
          PhoneNormalizer.normalize('0541234567', 'AE'),
        ).equals('+971541234567');
      });

      test('accepts 0551234567', () {
        check(
          PhoneNormalizer.normalize('0551234567', 'AE'),
        ).equals('+971551234567');
      });

      test('accepts 0581234567', () {
        check(
          PhoneNormalizer.normalize('0581234567', 'AE'),
        ).equals('+971581234567');
      });

      test('accepts already-normalized E.164', () {
        check(
          PhoneNormalizer.normalize('+971501234567', 'AE'),
        ).equals('+971501234567');
      });

      test('rejects Egyptian local number 010…', () {
        check(PhoneNormalizer.normalize('010234233422', 'AE')).isNull();
      });

      test('rejects UAE number when Egypt is selected', () {
        check(PhoneNormalizer.normalize('0501234567', 'EG')).isNull();
      });

      test('rejects Kuwait 65012345 when UAE is selected', () {
        check(PhoneNormalizer.normalize('65012345', 'AE')).isNull();
      });

      test('rejects partial number (too short)', () {
        check(PhoneNormalizer.normalize('050123', 'AE')).isNull();
      });
    });

    group('E.164 country matching', () {
      test('+201… accepted only for Egypt', () {
        check(PhoneNormalizer.normalize('+201012345678', 'EG')).isNotNull();
        check(PhoneNormalizer.normalize('+201012345678', 'AE')).isNull();
        check(PhoneNormalizer.normalize('+201012345678', 'SA')).isNull();
        check(PhoneNormalizer.normalize('+201012345678', 'KW')).isNull();
      });

      test('+9715… accepted only for UAE', () {
        check(PhoneNormalizer.normalize('+971501234567', 'AE')).isNotNull();
        check(PhoneNormalizer.normalize('+971501234567', 'EG')).isNull();
        check(PhoneNormalizer.normalize('+971501234567', 'SA')).isNull();
        check(PhoneNormalizer.normalize('+971501234567', 'KW')).isNull();
      });

      test('+9665… accepted only for Saudi', () {
        check(PhoneNormalizer.normalize('+966501234567', 'SA')).isNotNull();
        check(PhoneNormalizer.normalize('+966501234567', 'EG')).isNull();
        check(PhoneNormalizer.normalize('+966501234567', 'AE')).isNull();
      });

      test('+9656… accepted only for Kuwait', () {
        check(PhoneNormalizer.normalize('+96565012345', 'KW')).isNotNull();
        check(PhoneNormalizer.normalize('+96565012345', 'EG')).isNull();
        check(PhoneNormalizer.normalize('+96565012345', 'AE')).isNull();
      });
    });

    group('empty / invalid / partial input', () {
      test('returns null for empty string', () {
        check(PhoneNormalizer.normalize('', 'EG')).isNull();
      });

      test('returns null for whitespace only', () {
        check(PhoneNormalizer.normalize('   ', 'EG')).isNull();
      });

      test('returns null for whitespace only (KW)', () {
        check(PhoneNormalizer.normalize('   ', 'KW')).isNull();
      });

      test('returns null for obviously malformed input', () {
        check(PhoneNormalizer.normalize('abc', 'EG')).isNull();
      });

      test('returns null for partial Egyptian number', () {
        check(PhoneNormalizer.normalize('0101', 'EG')).isNull();
      });

      test('returns null for partial Kuwait number', () {
        check(PhoneNormalizer.normalize('650', 'KW')).isNull();
      });

      test('returns null for partial UAE number', () {
        check(PhoneNormalizer.normalize('0501', 'AE')).isNull();
      });
    });

    group('E.164 normalization', () {
      test('Egypt local → E.164', () {
        check(
          PhoneNormalizer.normalize('01012345678', 'EG'),
        ).equals('+201012345678');
      });

      test('Kuwait local → E.164', () {
        check(
          PhoneNormalizer.normalize('65012345', 'KW'),
        ).equals('+96565012345');
      });

      test('UAE local → E.164', () {
        check(
          PhoneNormalizer.normalize('0501234567', 'AE'),
        ).equals('+971501234567');
      });

      test('strips hyphens before normalizing', () {
        check(
          PhoneNormalizer.normalize('010-6009-9009', 'EG'),
        ).equals('+201060099009');
      });

      test('strips parentheses before normalizing', () {
        check(
          PhoneNormalizer.normalize('(010) 60099009', 'EG'),
        ).equals('+201060099009');
      });
    });
  });

  group('PhoneNormalizer.validate', () {
    group('Egypt', () {
      test('returns valid for correct Egyptian local number', () {
        check(
          PhoneNormalizer.validate('01012345678', 'EG'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns valid for 011x', () {
        check(
          PhoneNormalizer.validate('01112345678', 'EG'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns valid for 012x', () {
        check(
          PhoneNormalizer.validate('01212345678', 'EG'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns valid for 015x', () {
        check(
          PhoneNormalizer.validate('01512345678', 'EG'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns valid for E.164 +201012345678', () {
        check(
          PhoneNormalizer.validate('+201012345678', 'EG'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns invalid for partial 0101234 (too short)', () {
        check(
          PhoneNormalizer.validate('0101234', 'EG'),
        ).equals(PhoneValidationResult.invalid);
      });

      test('returns invalid for 65012345 (wrong length for EG)', () {
        check(
          PhoneNormalizer.validate('65012345', 'EG'),
        ).equals(PhoneValidationResult.invalid);
      });

      // ── Regression: 10-digit 010x must be invalid, not countryMismatch ───
      test(
        'regression: 0102020021 (10 digits, 010 prefix) → invalid, not countryMismatch',
        () {
          // Bug: 9 stripped digits coincidentally normalized as a Malaysian number,
          // triggering a false countryMismatch. Prefix guard must catch this first.
          check(
            PhoneNormalizer.validate('0102020021', 'EG'),
          ).equals(PhoneValidationResult.invalid);
        },
      );

      test(
        'regression: adding one digit to 0102020021 → valid (01020200213)',
        () {
          check(
            PhoneNormalizer.validate('01020200213', 'EG'),
          ).equals(PhoneValidationResult.valid);
        },
      );

      // ── Character-by-character for 010 prefix ────────────────────────────
      test('0 alone → invalid (too short)', () {
        check(PhoneNormalizer.validate('0', 'EG')).equals(
          PhoneValidationResult.invalid,
        );
      });

      test('01 → invalid (too short)', () {
        check(PhoneNormalizer.validate('01', 'EG')).equals(
          PhoneValidationResult.invalid,
        );
      });

      test('010 → invalid (too short)', () {
        check(PhoneNormalizer.validate('010', 'EG')).equals(
          PhoneValidationResult.invalid,
        );
      });

      test('0102020021 (10 digits) → invalid (one digit short)', () {
        check(PhoneNormalizer.validate('0102020021', 'EG')).equals(
          PhoneValidationResult.invalid,
        );
      });

      test('01020200213 (11 digits) → valid', () {
        check(PhoneNormalizer.validate('01020200213', 'EG')).equals(
          PhoneValidationResult.valid,
        );
      });

      test('010202002133 (12 digits) → invalid (too long)', () {
        check(PhoneNormalizer.validate('010202002133', 'EG')).equals(
          PhoneValidationResult.invalid,
        );
      });

      // ── Invalid Egyptian prefixes ─────────────────────────────────────────
      // 040x, 042x, 043x are not valid EG prefixes (only 010/011/012/015 are)
      // and do not coincidentally match any other strip-leading-zero country,
      // so they correctly return invalid rather than countryMismatch.
      test('040 prefix → invalid (not a real EG prefix)', () {
        check(PhoneNormalizer.validate('04012345678', 'EG')).equals(
          PhoneValidationResult.invalid,
        );
      });

      test('042 prefix → invalid', () {
        check(PhoneNormalizer.validate('04212345678', 'EG')).equals(
          PhoneValidationResult.invalid,
        );
      });

      test('043 prefix → invalid', () {
        check(PhoneNormalizer.validate('04312345678', 'EG')).equals(
          PhoneValidationResult.invalid,
        );
      });
    });

    group('Kuwait', () {
      test('returns valid for 65012345', () {
        check(
          PhoneNormalizer.validate('65012345', 'KW'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns valid for 50123456 (starts with 5)', () {
        check(
          PhoneNormalizer.validate('50123456', 'KW'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns valid for 90123456 (starts with 9)', () {
        check(
          PhoneNormalizer.validate('90123456', 'KW'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns valid for E.164 +96565012345', () {
        check(
          PhoneNormalizer.validate('+96565012345', 'KW'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns invalid for 01020030 — starts with 0', () {
        check(
          PhoneNormalizer.validate('01020030', 'KW'),
        ).equals(PhoneValidationResult.invalid);
      });

      test('returns countryMismatch for Egyptian 010x when KW selected', () {
        check(
          PhoneNormalizer.validate('01012345678', 'KW'),
        ).equals(PhoneValidationResult.countryMismatch);
      });

      test(
        'returns countryMismatch for E.164 +201012345678 when KW selected',
        () {
          check(
            PhoneNormalizer.validate('+201012345678', 'KW'),
          ).equals(PhoneValidationResult.countryMismatch);
        },
      );
    });

    group('UAE', () {
      test('returns valid for 0501234567', () {
        check(
          PhoneNormalizer.validate('0501234567', 'AE'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns valid for 0521234567', () {
        check(
          PhoneNormalizer.validate('0521234567', 'AE'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns valid for E.164 +971501234567', () {
        check(
          PhoneNormalizer.validate('+971501234567', 'AE'),
        ).equals(PhoneValidationResult.valid);
      });

      test('returns countryMismatch for Egyptian number with UAE selected', () {
        check(
          PhoneNormalizer.validate('01060099009', 'AE'),
        ).equals(PhoneValidationResult.countryMismatch);
      });

      test(
        'returns countryMismatch for E.164 Egypt number with UAE selected',
        () {
          check(
            PhoneNormalizer.validate('+201060099009', 'AE'),
          ).equals(PhoneValidationResult.countryMismatch);
        },
      );

      test('returns invalid for Kuwait 65012345 when UAE selected', () {
        check(
          PhoneNormalizer.validate('65012345', 'AE'),
        ).equals(PhoneValidationResult.invalid);
      });

      test('returns countryMismatch for UAE number with Egypt selected', () {
        check(
          PhoneNormalizer.validate('0501234567', 'EG'),
        ).equals(PhoneValidationResult.countryMismatch);
      });

      test('returns invalid for 01012345678 when UAE selected', () {
        // Length mismatch: would produce 11 local digits for AE (expects 9)
        check(
          PhoneNormalizer.validate('01012345678', 'AE'),
        ).equals(PhoneValidationResult.countryMismatch);
      });
    });

    group('empty / whitespace / partial', () {
      test('returns invalid for empty input', () {
        check(
          PhoneNormalizer.validate('', 'EG'),
        ).equals(PhoneValidationResult.invalid);
      });

      test('returns invalid for whitespace only', () {
        check(
          PhoneNormalizer.validate('   ', 'EG'),
        ).equals(PhoneValidationResult.invalid);
      });

      test('returns invalid for whitespace only (KW)', () {
        check(
          PhoneNormalizer.validate('   ', 'KW'),
        ).equals(PhoneValidationResult.invalid);
      });

      test('returns invalid for malformed number', () {
        check(
          PhoneNormalizer.validate('not-a-phone', 'EG'),
        ).equals(PhoneValidationResult.invalid);
      });

      test('returns invalid for partial Egyptian number 0101234', () {
        check(
          PhoneNormalizer.validate('0101234', 'EG'),
        ).equals(PhoneValidationResult.invalid);
      });

      test('returns invalid for partial Kuwait number 650', () {
        check(
          PhoneNormalizer.validate('650', 'KW'),
        ).equals(PhoneValidationResult.invalid);
      });
    });

    group('country switching revalidation', () {
      test('Egyptian number then switch to UAE → countryMismatch', () {
        const raw = '01060099009';
        check(
          PhoneNormalizer.validate(raw, 'EG'),
        ).equals(PhoneValidationResult.valid);
        check(
          PhoneNormalizer.validate(raw, 'AE'),
        ).equals(PhoneValidationResult.countryMismatch);
      });

      test('Kuwait number then switch to Egypt → invalid (wrong length)', () {
        const raw = '65012345';
        check(
          PhoneNormalizer.validate(raw, 'KW'),
        ).equals(PhoneValidationResult.valid);
        check(
          PhoneNormalizer.validate(raw, 'EG'),
        ).equals(PhoneValidationResult.invalid);
      });

      test('UAE E.164 number then switch to KW → countryMismatch', () {
        const raw = '+971501234567';
        check(
          PhoneNormalizer.validate(raw, 'AE'),
        ).equals(PhoneValidationResult.valid);
        check(
          PhoneNormalizer.validate(raw, 'KW'),
        ).equals(PhoneValidationResult.countryMismatch);
      });
    });
  });

  group('PhoneNormalizer.hint', () {
    test('returns Egypt-specific hint for EG', () {
      check(PhoneNormalizer.hint('EG')).equals('01012345678');
    });

    test('returns UAE-specific hint for AE', () {
      check(PhoneNormalizer.hint('AE')).equals('0501234567');
    });

    test('returns Kuwait-specific hint for KW', () {
      check(PhoneNormalizer.hint('KW')).equals('65012345');
    });

    test('returns generic placeholder for unknown country code', () {
      check(PhoneNormalizer.hint('XX')).equals('XXXXXXXXX');
    });
  });

  group('PhoneNormalizer.formatGuide', () {
    test('includes both local and E.164 formats for Egypt', () {
      final guide = PhoneNormalizer.formatGuide('EG');
      check(guide).contains('01012345678');
      check(guide).contains('+201012345678');
    });

    test('includes both local and E.164 formats for UAE', () {
      final guide = PhoneNormalizer.formatGuide('AE');
      check(guide).contains('0501234567');
      check(guide).contains('+971501234567');
    });

    test('includes both local and E.164 formats for Kuwait', () {
      final guide = PhoneNormalizer.formatGuide('KW');
      check(guide).contains('65012345');
      check(guide).contains('+96565012345');
    });

    test('returns fallback string for unknown country code', () {
      check(PhoneNormalizer.formatGuide('XX')).equals('XXXXXXXXX');
    });
  });

  group('PhoneNormalizer.isValid', () {
    test('returns true for valid Egyptian number', () {
      check(PhoneNormalizer.isValid('01012345678', 'EG')).isTrue();
    });

    test('returns false for invalid number', () {
      check(PhoneNormalizer.isValid('0101234', 'EG')).isFalse();
    });

    test('returns false for wrong country', () {
      check(PhoneNormalizer.isValid('01012345678', 'AE')).isFalse();
    });
  });

  group('PhoneNormalizer.dialCode', () {
    test('returns dial code for known country', () {
      check(PhoneNormalizer.dialCode('EG')).equals('+20');
      check(PhoneNormalizer.dialCode('AE')).equals('+971');
      check(PhoneNormalizer.dialCode('KW')).equals('+965');
    });

    test('returns empty string for unknown country code', () {
      check(PhoneNormalizer.dialCode('XX')).equals('');
    });
  });

  group('PhoneNormalizer.validate — coverage gaps', () {
    test('unknown country code → invalid', () {
      check(
        PhoneNormalizer.validate('01012345678', 'XX'),
      ).equals(PhoneValidationResult.invalid);
    });

    test('unknown country code with E.164 input → countryMismatch', () {
      // E.164 path: valid format but no country match
      check(
        PhoneNormalizer.validate('+201012345678', 'XX'),
      ).equals(PhoneValidationResult.countryMismatch);
    });

    test(
      'US number accepted without prefix restriction (no _localStartsWith entry)',
      () {
        // +1 + 2015551234 = 10 local digits; US has no prefix rule so any 10-digit US number is valid
        check(
          PhoneNormalizer.validate('+12015551234', 'US'),
        ).equals(PhoneValidationResult.valid);
      },
    );

    test('CA number accepted without prefix restriction', () {
      check(
        PhoneNormalizer.validate('+16135551234', 'CA'),
      ).equals(PhoneValidationResult.valid);
    });

    test(
      'local 0-prefix number that does not match any other country → invalid',
      () {
        // 0000000000 with EG: prefix guard skips (does not start with 10/11/12/15),
        // _looksLikeOtherCountryLocal returns false because no country's rules accept it.
        check(
          PhoneNormalizer.validate('0000000000', 'EG'),
        ).equals(PhoneValidationResult.invalid);
      },
    );
  });

  group('PhoneNormalizer.normalize — coverage gaps', () {
    test('unknown country code → null', () {
      check(PhoneNormalizer.normalize('01012345678', 'XX')).isNull();
    });

    test('US E.164 normalizes correctly', () {
      check(
        PhoneNormalizer.normalize('+12015551234', 'US'),
      ).equals('+12015551234');
    });
  });
}
