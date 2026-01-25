import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/history/data/datasources/history_local_datasource.dart';
import 'package:tilawa/features/history/data/repositories/history_repository_impl.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';

class MockHistoryLocalDataSource extends Mock
    implements HistoryLocalDataSource {}

void main() {
  late HistoryRepositoryImpl repository;
  late MockHistoryLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockHistoryLocalDataSource();
    repository = HistoryRepositoryImpl(mockLocalDataSource);
    registerFallbackValue(
      HistoryEntity(
        id: '1',
        surahId: 1,
        surahName: '',
        surahNameEn: '',
        reciterId: '',
        reciterName: '',
        moshafId: 1,
        moshafName: '',
        lastPositionMs: 0,
        durationMs: 0,
        audioUrl: '',
        playedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  });

  final tHistoryEntity = HistoryEntity(
    id: '1',
    surahId: 1,
    surahName: 'Al-Fatihah',
    surahNameEn: 'The Opening',
    reciterId: '1',
    reciterName: 'Mishary Rashid Alafasy',
    moshafId: 1,
    moshafName: 'Hafs',
    lastPositionMs: 1000,
    durationMs: 5000,
    audioUrl: 'url',
    playedAt: DateTime.fromMicrosecondsSinceEpoch(0), // Fixed time
  );

  group('getAllHistory', () {
    test('should return list of history from local data source', () async {
      // arrange
      when(
        () => mockLocalDataSource.getAllHistory(),
      ).thenAnswer((_) async => [tHistoryEntity]);

      // act
      final result = await repository.getAllHistory();

      // assert
      expect(result, [tHistoryEntity]);
      verify(() => mockLocalDataSource.getAllHistory()).called(1);
    });
  });

  group('getRecentHistory', () {
    test('should return limited list of history', () async {
      // arrange
      when(
        () => mockLocalDataSource.getAllHistory(),
      ).thenAnswer((_) async => [tHistoryEntity, tHistoryEntity]);

      // act
      final result = await repository.getRecentHistory(limit: 1);

      // assert
      expect(result.length, 1);
      verify(() => mockLocalDataSource.getAllHistory()).called(1);
    });
  });

  group('addOrUpdateHistory', () {
    const surahId = 1;
    const reciterId = '1';
    const moshafId = 1;

    test('should update existing history when it exists', () async {
      // arrange
      const compositeKey = '${surahId}_${reciterId}_$moshafId';
      when(
        () => mockLocalDataSource.generateCompositeKey(
          surahId: surahId,
          reciterId: reciterId,
          moshafId: moshafId,
        ),
      ).thenReturn(compositeKey);
      when(
        () => mockLocalDataSource.getHistoryByCompositeKey(compositeKey),
      ).thenAnswer((_) async => tHistoryEntity);
      when(
        () => mockLocalDataSource.saveHistory(any()),
      ).thenAnswer((_) async {});

      // act
      await repository.addOrUpdateHistory(
        surahId: surahId,
        surahName: 'Al-Fatihah',
        surahNameEn: 'The Opening',
        reciterId: reciterId,
        reciterName: 'Name',
        moshafId: moshafId,
        moshafName: 'Hafs',
        lastPositionMs: 2000,
        durationMs: 5000,
        audioUrl: 'url',
      );

      // assert
      verify(
        () => mockLocalDataSource.getHistoryByCompositeKey(compositeKey),
      ).called(1);
      verify(() => mockLocalDataSource.saveHistory(any())).called(1);
    });

    test('should create new history when it does not exist', () async {
      // arrange
      const compositeKey = '${surahId}_${reciterId}_$moshafId';
      when(
        () => mockLocalDataSource.generateCompositeKey(
          surahId: surahId,
          reciterId: reciterId,
          moshafId: moshafId,
        ),
      ).thenReturn(compositeKey);
      when(
        () => mockLocalDataSource.getHistoryByCompositeKey(compositeKey),
      ).thenAnswer((_) async => null);
      when(
        () => mockLocalDataSource.saveHistory(any()),
      ).thenAnswer((_) async {});

      // act
      final result = await repository.addOrUpdateHistory(
        surahId: surahId,
        surahName: 'Al-Fatihah',
        surahNameEn: 'The Opening',
        reciterId: reciterId,
        reciterName: 'Name',
        moshafId: moshafId,
        moshafName: 'Hafs',
        lastPositionMs: 2000,
        durationMs: 5000,
        audioUrl: 'url',
      );

      // assert
      expect(result.id, compositeKey);
      verify(
        () => mockLocalDataSource.getHistoryByCompositeKey(compositeKey),
      ).called(1);
      verify(() => mockLocalDataSource.saveHistory(any())).called(1);
    });

    test(
      'should preserve existing duration when update has 0 duration',
      () async {
        // arrange
        const compositeKey = '${surahId}_${reciterId}_$moshafId';
        final existingHistory = tHistoryEntity.copyWith(durationMs: 5000);
        when(
          () => mockLocalDataSource.generateCompositeKey(
            surahId: surahId,
            reciterId: reciterId,
            moshafId: moshafId,
          ),
        ).thenReturn(compositeKey);
        when(
          () => mockLocalDataSource.getHistoryByCompositeKey(compositeKey),
        ).thenAnswer((_) async => existingHistory);
        when(
          () => mockLocalDataSource.saveHistory(any()),
        ).thenAnswer((_) async {});

        // act
        await repository.addOrUpdateHistory(
          surahId: surahId,
          surahName: 'Al-Fatihah',
          surahNameEn: 'The Opening',
          reciterId: reciterId,
          reciterName: 'Name',
          moshafId: moshafId,
          moshafName: 'Hafs',
          lastPositionMs: 2000,
          durationMs: 0, // Sending 0 duration
          audioUrl: 'url',
        );

        // assert
        final captured = verify(
          () => mockLocalDataSource.saveHistory(captureAny()),
        ).captured;
        final savedHistory = captured.first as HistoryEntity;
        expect(savedHistory.durationMs, 5000);
      },
    );
  });

  group('getTotalListeningTime', () {
    test('should return sum of lastPositionMs', () async {
      // arrange
      final history1 = tHistoryEntity.copyWith(lastPositionMs: 1000);
      final history2 = tHistoryEntity.copyWith(lastPositionMs: 2000);
      when(
        () => mockLocalDataSource.getAllHistory(),
      ).thenAnswer((_) async => [history1, history2]);

      // act
      final result = await repository.getTotalListeningTime();

      // assert
      expect(result, 3000);
    });
  });

  group('deleteHistory', () {
    test('should call deleteHistory on data source', () async {
      // arrange
      const id = '1';
      when(
        () => mockLocalDataSource.deleteHistory(id),
      ).thenAnswer((_) async {});

      // act
      await repository.deleteHistory(id);

      // assert
      verify(() => mockLocalDataSource.deleteHistory(id)).called(1);
    });
  });

  group('deleteAllHistory', () {
    test('should call clearAllHistory on data source', () async {
      // arrange
      when(
        () => mockLocalDataSource.clearAllHistory(),
      ).thenAnswer((_) async {});

      // act
      await repository.deleteAllHistory();

      // assert
      verify(() => mockLocalDataSource.clearAllHistory()).called(1);
    });
  });
  group('getHistoryByDateRange', () {
    test('should return history within date range', () async {
      // arrange
      final now = DateTime.now();
      final history1 = tHistoryEntity.copyWith(
        playedAt: now.subtract(const Duration(days: 1)),
      );
      final history2 = tHistoryEntity.copyWith(
        playedAt: now.subtract(const Duration(days: 3)),
      );

      when(
        () => mockLocalDataSource.getAllHistory(),
      ).thenAnswer((_) async => [history1, history2]);

      // act
      final result = await repository.getHistoryByDateRange(
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now,
      );

      // assert
      expect(result.length, 1);
      expect(result.first, history1);
    });
  });

  group('getHistoryByReciter', () {
    test('should return history for specific reciter', () async {
      // arrange
      final history1 = tHistoryEntity.copyWith(reciterId: '1');
      final history2 = tHistoryEntity.copyWith(reciterId: '2');

      when(
        () => mockLocalDataSource.getAllHistory(),
      ).thenAnswer((_) async => [history1, history2]);

      // act
      final result = await repository.getHistoryByReciter('1');

      // assert
      expect(result.length, 1);
      expect(result.first, history1);
    });
  });

  group('getHistoryById', () {
    test('should return history by id', () async {
      // arrange
      when(
        () => mockLocalDataSource.getHistoryById('1'),
      ).thenAnswer((_) async => tHistoryEntity);

      // act
      final result = await repository.getHistoryById('1');

      // assert
      expect(result, tHistoryEntity);
      verify(() => mockLocalDataSource.getHistoryById('1')).called(1);
    });
  });

  group('updateLastPosition', () {
    test('should update last position if history exists', () async {
      // arrange
      when(
        () => mockLocalDataSource.getHistoryById('1'),
      ).thenAnswer((_) async => tHistoryEntity);
      when(
        () => mockLocalDataSource.saveHistory(any()),
      ).thenAnswer((_) async {});

      // act
      final result = await repository.updateLastPosition(
        id: '1',
        lastPositionMs: 5000,
        completed: true,
      );

      // assert
      expect(result?.lastPositionMs, 5000);
      expect(result?.completed, true);
      verify(() => mockLocalDataSource.saveHistory(any())).called(1);
    });

    test('should return null if history does not exist', () async {
      // arrange
      when(
        () => mockLocalDataSource.getHistoryById('1'),
      ).thenAnswer((_) async => null);

      // act
      final result = await repository.updateLastPosition(
        id: '1',
        lastPositionMs: 5000,
      );

      // assert
      expect(result, null);
      verifyNever(() => mockLocalDataSource.saveHistory(any()));
    });
  });

  group('deleteHistoryOlderThan', () {
    test('should delete history older than date', () async {
      // arrange
      final now = DateTime.now();
      final history1 = tHistoryEntity.copyWith(playedAt: now);
      final history2 = tHistoryEntity.copyWith(
        playedAt: now.subtract(const Duration(days: 10)),
      );

      when(
        () => mockLocalDataSource.getAllHistory(),
      ).thenAnswer((_) async => [history1, history2]);
      when(
        () => mockLocalDataSource.saveAllHistory(any()),
      ).thenAnswer((_) async {});

      // act
      await repository.deleteHistoryOlderThan(
        now.subtract(const Duration(days: 5)),
      );

      // assert
      verify(() => mockLocalDataSource.saveAllHistory(any())).called(1);
    });
  });

  group('searchHistory', () {
    test('should return matching history', () async {
      // arrange
      final history1 = tHistoryEntity.copyWith(surahName: 'Al-Fatihah');
      final history2 = tHistoryEntity.copyWith(surahName: 'Al-Baqarah');

      when(
        () => mockLocalDataSource.getAllHistory(),
      ).thenAnswer((_) async => [history1, history2]);

      // act
      final result = await repository.searchHistory('Fatihah');

      // assert
      expect(result.length, 1);
      expect(result.first, history1);
    });
  });

  group('getHistoryCount', () {
    test('should return history count', () async {
      // arrange
      when(
        () => mockLocalDataSource.getHistoryCount(),
      ).thenAnswer((_) async => 5);

      // act
      final result = await repository.getHistoryCount();

      // assert
      expect(result, 5);
    });
  });

  group('getMostPlayedSurahs', () {
    test('should return most played surahs', () async {
      // arrange
      final history1 = tHistoryEntity.copyWith(playCount: 5);
      final history2 = tHistoryEntity.copyWith(playCount: 10);

      when(
        () => mockLocalDataSource.getAllHistory(),
      ).thenAnswer((_) async => [history1, history2]);

      // act
      final result = await repository.getMostPlayedSurahs(limit: 2);

      // assert
      expect(result.length, 2);
      expect(result.first, history2); // Most played first
    });
  });

  group('hasBeenPlayed', () {
    test('should return true if history exists', () async {
      // arrange
      when(
        () => mockLocalDataSource.getHistoryByKey(
          surahId: 1,
          reciterId: '1',
          moshafId: 1,
        ),
      ).thenAnswer((_) async => tHistoryEntity);

      // act
      final result = await repository.hasBeenPlayed(
        surahId: 1,
        reciterId: '1',
        moshafId: 1,
      );

      // assert
      expect(result, true);
    });
  });
}
