import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';

import '../../../../support/map_backed_shared_preferences_async.dart';

void main() {
  const String storageKey = 'smart_khatma.active_plan.v2';

  test('round-trips confirmed progress and frozen assignment', () async {
    final preferences = MapBackedSharedPreferencesAsync(<String, Object>{});
    final dataSource = SharedPreferencesKhatmaPlanLocalDataSource(
      preferences.prefs,
    );
    final plan = _plan(confirmedThrough: 8);

    await dataSource.saveActivePlan(plan);
    final restored = await dataSource.getActivePlan();

    expect(restored?.confirmedCompletedThroughPage, 8);
    expect(restored?.assignmentStartPage, 1);
    expect(restored?.assignmentEndPage, 21);
    expect(restored?.resumePage, 9);
  });

  test('ignores unreleased v1 development data', () async {
    final preferences = MapBackedSharedPreferencesAsync(<String, Object>{
      'smart_khatma.active_plan.v1': jsonEncode(<String, Object>{
        'current_page': 50,
      }),
    });

    final plan = await SharedPreferencesKhatmaPlanLocalDataSource(
      preferences.prefs,
    ).getActivePlan();

    expect(plan, isNull);
  });

  test('malformed v2 data does not crash or overwrite the raw value', () async {
    const String raw = '{invalid';
    final preferences = MapBackedSharedPreferencesAsync(<String, Object>{
      storageKey: raw,
    });

    final future = SharedPreferencesKhatmaPlanLocalDataSource(
      preferences.prefs,
    ).getActivePlan();

    await expectLater(future, throwsFormatException);
    expect(preferences.store[storageKey], raw);
  });

  test('rejects confirmed pages outside plan bounds', () async {
    final preferences = MapBackedSharedPreferencesAsync(<String, Object>{});
    final dataSource = SharedPreferencesKhatmaPlanLocalDataSource(
      preferences.prefs,
    );
    await dataSource.saveActivePlan(_plan());
    final json =
        jsonDecode(preferences.store[storageKey]! as String)
            as Map<String, Object?>;
    json['confirmed_completed_through_page'] = 605;
    preferences.store[storageKey] = jsonEncode(json);

    await expectLater(dataSource.getActivePlan(), throwsFormatException);
  });
}

KhatmaPlan _plan({int? confirmedThrough}) => KhatmaPlan(
  id: 'plan-1',
  createdAt: DateTime(2026, 7, 12),
  startDate: DateTime(2026, 7, 12),
  durationDays: 30,
  startPage: 1,
  targetPage: 604,
  confirmedCompletedThroughPage: confirmedThrough,
  assignmentDate: DateTime(2026, 7, 12),
  assignmentStartPage: 1,
  assignmentEndPage: 21,
);
