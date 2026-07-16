import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tilawa/features/tour_guide/data/datasources/tour_progress_local_datasource.dart';
import 'package:tilawa/features/tour_guide/domain/entities/tour_completion_record.dart';

import 'tour_progress_local_datasource_test.mocks.dart';

@GenerateMocks([SharedPreferencesAsync])
void main() {
  late MockSharedPreferencesAsync mockPrefs;
  late TourProgressLocalDataSourceImpl dataSource;

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    dataSource = TourProgressLocalDataSourceImpl(mockPrefs);
  });

  group('read', () {
    test('returns defaults when keys are missing', () async {
      when(
        mockPrefs.getBool('tour_guide_sample_completed'),
      ).thenAnswer((_) async => null);
      when(
        mockPrefs.getInt('tour_guide_sample_version'),
      ).thenAnswer((_) async => null);

      final record = await dataSource.read('sample');

      expect(record.completed, isFalse);
      expect(record.completedVersion, 0);
    });

    test('returns stored values', () async {
      when(
        mockPrefs.getBool('tour_guide_sample_completed'),
      ).thenAnswer((_) async => true);
      when(
        mockPrefs.getInt('tour_guide_sample_version'),
      ).thenAnswer((_) async => 2);

      final record = await dataSource.read('sample');

      expect(record.completed, isTrue);
      expect(record.completedVersion, 2);
    });
  });

  group('write', () {
    test('persists completion and version', () async {
      when(
        mockPrefs.setBool('tour_guide_sample_completed', true),
      ).thenAnswer((_) async => true);
      when(
        mockPrefs.setInt('tour_guide_sample_version', 3),
      ).thenAnswer((_) async => true);

      await dataSource.write(
        tourId: 'sample',
        record: const TourCompletionRecord(
          completed: true,
          completedVersion: 3,
        ),
      );

      verify(mockPrefs.setBool('tour_guide_sample_completed', true)).called(1);
      verify(mockPrefs.setInt('tour_guide_sample_version', 3)).called(1);
    });
  });

  group('clearAll', () {
    test('removes only tour_guide_ keys', () async {
      when(mockPrefs.getKeys()).thenAnswer(
        (_) async => <String>{
          'tour_guide_a_completed',
          'onboarding_completed',
          'tour_guide_b_version',
        },
      );
      when(mockPrefs.remove(any)).thenAnswer((_) async {
        return;
      });

      await dataSource.clearAll();

      verify(mockPrefs.remove('tour_guide_a_completed')).called(1);
      verify(mockPrefs.remove('tour_guide_b_version')).called(1);
      verifyNever(mockPrefs.remove('onboarding_completed'));
    });
  });
}
