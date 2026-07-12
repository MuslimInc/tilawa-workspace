import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../../../support/map_backed_shared_preferences_async.dart';

void main() {
  const String storageKey = 'smart_khatma.active_plan.v1';

  test('loads a legacy active plan with missing optional fields', () async {
    final preferences = MapBackedSharedPreferencesAsync(<String, Object>{
      storageKey: jsonEncode(_legacyPlanJson()),
    });
    final dataSource = SharedPreferencesKhatmaPlanLocalDataSource(
      preferences.prefs,
    );

    final plan = await dataSource.getActivePlan();

    expect(plan?.adjustment, KhatmaPlanAdjustment.none);
    expect(plan?.adjustmentDate, isNull);
    expect(plan?.progressDate, isNull);
    expect(plan?.progressStartPage, isNull);
  });

  test('legacy plan can progress and retain legacy fields on save', () async {
    final preferences = MapBackedSharedPreferencesAsync(<String, Object>{
      storageKey: jsonEncode(_legacyPlanJson()),
    });
    final dataSource = SharedPreferencesKhatmaPlanLocalDataSource(
      preferences.prefs,
    );
    final plan = await dataSource.getActivePlan();

    final repository = KhatmaPlanRepositoryImpl(dataSource);
    await UpdateKhatmaProgressUseCase(
      repository,
      _FakeAnalyticsService(),
      now: () => DateTime(2026, 7, 12),
    )(currentPage: plan!.currentPage + 1);
    final saved =
        jsonDecode(preferences.store[storageKey]! as String)
            as Map<String, Object?>;

    expect(saved['id'], 'local-plan');
    expect(saved['duration_days'], 30);
    expect(saved['current_page'], 13);
    expect(saved['progress_start_page'], 12);
  });

  test('invalid persisted baseline is ignored as a missing plan', () async {
    final json = _legacyPlanJson()
      ..addAll(<String, Object?>{
        'progress_date': '2026-07-12T00:00:00.000',
        'progress_start_page': -1,
      });
    final preferences = MapBackedSharedPreferencesAsync(<String, Object>{
      storageKey: jsonEncode(json),
    });
    final repository = KhatmaPlanRepositoryImpl(
      SharedPreferencesKhatmaPlanLocalDataSource(preferences.prefs),
    );

    final result = await GetWirdProgressSummaryUseCase(
      repository,
      now: () => DateTime(2026, 7, 12),
    )();

    expect(result.isRight(), isTrue);
    expect(
      result.getOrElse(() => throw StateError('expected summary')).planStatus,
      WirdProgressPlanStatus.none,
    );
  });

  test('loads explicit null optional fields', () async {
    final json = _legacyPlanJson()
      ..addAll(<String, Object?>{
        'adjustment': 'none',
        'adjustment_date': null,
        'progress_date': null,
        'progress_start_page': null,
      });
    final preferences = MapBackedSharedPreferencesAsync(<String, Object>{
      storageKey: jsonEncode(json),
    });

    final plan = await SharedPreferencesKhatmaPlanLocalDataSource(
      preferences.prefs,
    ).getActivePlan();

    expect(plan, isNotNull);
    expect(plan?.progressDate, isNull);
  });

  test('rejects malformed checkpoint and unknown adjustment data', () async {
    for (final corruptFields in <Map<String, Object?>>[
      <String, Object?>{'progress_date': 'not-a-date'},
      <String, Object?>{'adjustment': 'unknown'},
    ]) {
      final preferences = MapBackedSharedPreferencesAsync(<String, Object>{
        storageKey: jsonEncode(_legacyPlanJson()..addAll(corruptFields)),
      });

      final plan = await SharedPreferencesKhatmaPlanLocalDataSource(
        preferences.prefs,
      ).getActivePlan();

      expect(plan, isNull);
    }
  });
}

Map<String, Object?> _legacyPlanJson() => <String, Object?>{
  'id': 'local-plan',
  'created_at': '2026-07-01T09:00:00.000',
  'start_date': '2026-07-01T00:00:00.000',
  'duration_days': 30,
  'start_page': 1,
  'target_page': 604,
  'current_page': 12,
  'reading_style': 'pages',
  'preferred_minutes_per_day': null,
  'status': 'active',
};

final class _FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
