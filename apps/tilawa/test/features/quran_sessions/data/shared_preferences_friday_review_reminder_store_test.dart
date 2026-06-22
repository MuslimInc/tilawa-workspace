import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/quran_sessions/data/shared_preferences_friday_review_reminder_store.dart';

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late MockSharedPreferencesAsync prefs;
  late Map<String, int> backing;
  late SharedPreferencesFridayReviewReminderStore store;

  setUp(() {
    prefs = MockSharedPreferencesAsync();
    backing = <String, int>{};
    when(() => prefs.getInt(any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      return backing[key];
    });
    when(() => prefs.setInt(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as int;
      backing[key] = value;
    });
    store = SharedPreferencesFridayReviewReminderStore(prefs);
  });

  test('isDismissed returns false when key is missing', () async {
    final dismissed = await store.isDismissed(
      teacherId: 'teacher_1',
      nextWeekKey: '2026-W03',
    );

    expect(dismissed, isFalse);
  });

  test('dismiss persists until timestamp across store instances', () async {
    final until = DateTime.now().add(const Duration(hours: 2));

    await store.dismiss(
      teacherId: 'teacher_1',
      nextWeekKey: '2026-W03',
      until: until,
    );

    final reloaded = SharedPreferencesFridayReviewReminderStore(prefs);
    expect(
      await reloaded.isDismissed(
        teacherId: 'teacher_1',
        nextWeekKey: '2026-W03',
      ),
      isTrue,
    );
    expect(
      await reloaded.isDismissed(
        teacherId: 'teacher_2',
        nextWeekKey: '2026-W03',
      ),
      isFalse,
    );
  });

  test('isDismissed returns false after until expires', () async {
    await store.dismiss(
      teacherId: 'teacher_1',
      nextWeekKey: '2026-W03',
      until: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    expect(
      await store.isDismissed(
        teacherId: 'teacher_1',
        nextWeekKey: '2026-W03',
      ),
      isFalse,
    );
  });
}
