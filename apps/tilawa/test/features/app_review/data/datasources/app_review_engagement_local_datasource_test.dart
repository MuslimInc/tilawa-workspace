import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/app_review/data/datasources/app_review_engagement_local_datasource.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_engagement.dart';

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late MockSharedPreferencesAsync prefs;
  late AppReviewEngagementLocalDataSourceImpl dataSource;

  setUp(() {
    prefs = MockSharedPreferencesAsync();
    dataSource = AppReviewEngagementLocalDataSourceImpl(prefs);
    when(() => prefs.getInt(any())).thenAnswer((_) async => null);
    when(() => prefs.getString(any())).thenAnswer((_) async => null);
    when(() => prefs.setInt(any(), any())).thenAnswer((_) async {});
    when(() => prefs.setString(any(), any())).thenAnswer((_) async {});
  });

  test('read returns empty engagement when prefs are empty', () async {
    final AppReviewEngagement result = await dataSource.read();
    expect(result, const AppReviewEngagement());
  });

  test('write persists counters and optional fields', () async {
    const AppReviewEngagement engagement = AppReviewEngagement(
      sessionCount: 3,
      distinctActiveDays: 2,
      listeningCompletions: 1,
      firstSeenAtMs: 1000,
      lastPromptAtMs: 2000,
      lastSessionDayKey: '2026-05-21',
      lastActiveDayKey: '2026-05-22',
    );

    await dataSource.write(engagement);

    verify(() => prefs.setInt(any(), any())).called(greaterThan(5));
    verify(() => prefs.setString(any(), any())).called(2);
  });
}
