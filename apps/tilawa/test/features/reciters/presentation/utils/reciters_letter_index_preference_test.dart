import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/reciters/presentation/utils/reciter_list_moshaf_label.dart';
import 'package:tilawa/features/reciters/presentation/utils/reciters_letter_index_preference.dart';

class _MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late _MockSharedPreferencesAsync prefs;
  late RecitersLetterIndexPreference store;

  setUp(() {
    prefs = _MockSharedPreferencesAsync();
    store = RecitersLetterIndexPreference(prefs);
  });

  group('RecitersLetterIndexPreference.loadSavedVisibility', () {
    test('returns null when user has never toggled', () async {
      when(() => prefs.getBool(RecitersLetterIndexPreference.userSetKey))
          .thenAnswer((_) async => null);

      expect(await store.loadSavedVisibility(), isNull);
      verify(() => prefs.getBool(RecitersLetterIndexPreference.userSetKey))
          .called(1);
      verifyNever(() => prefs.getBool(RecitersLetterIndexPreference.showKey));
    });

    test('returns null when userSet is explicitly false', () async {
      when(() => prefs.getBool(RecitersLetterIndexPreference.userSetKey))
          .thenAnswer((_) async => false);

      expect(await store.loadSavedVisibility(), isNull);
      verifyNever(() => prefs.getBool(RecitersLetterIndexPreference.showKey));
    });

    test('returns false when user saved off state', () async {
      when(() => prefs.getBool(RecitersLetterIndexPreference.userSetKey))
          .thenAnswer((_) async => true);
      when(() => prefs.getBool(RecitersLetterIndexPreference.showKey))
          .thenAnswer((_) async => false);

      expect(await store.loadSavedVisibility(), isFalse);
    });

    test('returns true when user saved on state', () async {
      when(() => prefs.getBool(RecitersLetterIndexPreference.userSetKey))
          .thenAnswer((_) async => true);
      when(() => prefs.getBool(RecitersLetterIndexPreference.showKey))
          .thenAnswer((_) async => true);

      expect(await store.loadSavedVisibility(), isTrue);
    });

    test('returns false when userSet true but show key missing', () async {
      when(() => prefs.getBool(RecitersLetterIndexPreference.userSetKey))
          .thenAnswer((_) async => true);
      when(() => prefs.getBool(RecitersLetterIndexPreference.showKey))
          .thenAnswer((_) async => null);

      expect(await store.loadSavedVisibility(), isFalse);
    });
  });

  group('RecitersLetterIndexPreference.saveVisibility', () {
    test('persists show flag and marks user preference as set', () async {
      when(
        () => prefs.setBool(RecitersLetterIndexPreference.showKey, false),
      ).thenAnswer((_) async {});
      when(
        () => prefs.setBool(RecitersLetterIndexPreference.userSetKey, true),
      ).thenAnswer((_) async {});

      await store.saveVisibility(false);

      verifyInOrder([
        () => prefs.setBool(RecitersLetterIndexPreference.showKey, false),
        () => prefs.setBool(RecitersLetterIndexPreference.userSetKey, true),
      ]);
    });

    test('persists on state', () async {
      when(
        () => prefs.setBool(RecitersLetterIndexPreference.showKey, true),
      ).thenAnswer((_) async {});
      when(
        () => prefs.setBool(RecitersLetterIndexPreference.userSetKey, true),
      ).thenAnswer((_) async {});

      await store.saveVisibility(true);

      verify(
        () => prefs.setBool(RecitersLetterIndexPreference.showKey, true),
      ).called(1);
    });
  });

  group('letterIndexDefaultVisibleForWidth', () {
    test('is false below breakpoint', () {
      expect(
        letterIndexDefaultVisibleForWidth(
          kRecitersAlphabetDefaultVisibleBreakpoint - 1,
        ),
        isFalse,
      );
    });

    test('is true at breakpoint', () {
      expect(
        letterIndexDefaultVisibleForWidth(
          kRecitersAlphabetDefaultVisibleBreakpoint,
        ),
        isTrue,
      );
    });

    test('is true above breakpoint', () {
      expect(
        letterIndexDefaultVisibleForWidth(
          kRecitersAlphabetDefaultVisibleBreakpoint + 100,
        ),
        isTrue,
      );
    });
  });
}
