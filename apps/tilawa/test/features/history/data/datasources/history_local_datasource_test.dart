import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/services/hive_readiness.dart';
import 'package:tilawa/features/history/data/datasources/history_local_datasource.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import '../../../../core/helpers/fake_hive_readiness.dart';

class MockHiveInterface extends Mock implements HiveInterface {}

class MockBox extends Mock implements Box {}

void main() {
  late HistoryLocalDataSourceImpl dataSource;
  late MockHiveInterface mockHive;
  late MockBox mockBox;
  late HiveReadiness hiveReadiness;
  const historyBoxName = 'listening_history';

  setUp(() {
    mockHive = MockHiveInterface();
    mockBox = MockBox();
    hiveReadiness = ImmediateHiveReadiness();
    dataSource = HistoryLocalDataSourceImpl(mockHive, hiveReadiness);

    when(
      () => mockHive.openBox(historyBoxName),
    ).thenAnswer((_) async => mockBox);
    when(() => mockHive.isBoxOpen(historyBoxName)).thenReturn(false);
    // Default box behavior
    when(() => mockBox.isOpen).thenReturn(true);
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
    playedAt: DateTime.fromMicrosecondsSinceEpoch(0),
  );

  group('getAllHistory', () {
    test('waits for hive readiness before opening box', () async {
      final FakeHiveReadiness gate = FakeHiveReadiness();
      final HistoryLocalDataSourceImpl gatedSource = HistoryLocalDataSourceImpl(
        mockHive,
        gate,
      );
      when(() => mockBox.values).thenReturn([]);

      final Future<List<HistoryEntity>> pending = gatedSource.getAllHistory();
      await Future<void>.delayed(Duration.zero);
      expect(gate.ensureReadyCallCount, 1);
      verifyNever(() => mockHive.openBox(historyBoxName));

      gate.release();
      await pending;
      verify(() => mockHive.openBox(historyBoxName)).called(1);
    });

    test('should return list of HistoryEntity from Box', () async {
      // arrange
      final jsonString = jsonEncode(tHistoryEntity.toJson());
      when(() => mockBox.values).thenReturn([jsonString]);

      // act
      final result = await dataSource.getAllHistory();

      // assert
      expect(result.length, 1);
      expect(result.first.id, tHistoryEntity.id);
      verify(() => mockHive.openBox(historyBoxName)).called(1);
    });

    test('should return empty list when Box is empty', () async {
      // arrange
      when(() => mockBox.values).thenReturn([]);

      // act
      final result = await dataSource.getAllHistory();

      // assert
      expect(result, isEmpty);
    });

    test('should filter out non-string values (like counter)', () async {
      // arrange
      final jsonString = jsonEncode(tHistoryEntity.toJson());
      when(
        () => mockBox.values,
      ).thenReturn([jsonString, 123]); // 123 is counter

      // act
      final result = await dataSource.getAllHistory();

      // assert
      expect(result.length, 1);
      expect(result.first.id, tHistoryEntity.id);
    });
  });

  group('getHistoryById', () {
    test('should return history from Box if exists', () async {
      // arrange
      final jsonString = jsonEncode(tHistoryEntity.toJson());
      when(() => mockBox.get('1')).thenReturn(jsonString);

      // act
      final result = await dataSource.getHistoryById('1');

      // assert
      expect(result?.id, '1');
    });

    test('should return null if not found', () async {
      // arrange
      when(() => mockBox.get('1')).thenReturn(null);

      // act
      final result = await dataSource.getHistoryById('1');

      // assert
      expect(result, null);
    });
  });

  group('saveHistory', () {
    test('should put history into Box', () async {
      // arrange
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      when(() => mockBox.values).thenReturn([]); // Empty box

      // act
      await dataSource.saveHistory(tHistoryEntity);

      // assert
      verify(() => mockBox.put(tHistoryEntity.id, any())).called(1);
    });

    test('should trim history if limit exceeded', () async {
      // Mock a full box
      final historyList = List.generate(
        501,
        (index) => tHistoryEntity.copyWith(
          id: '$index',
          playedAt: DateTime.fromMicrosecondsSinceEpoch(index),
        ),
      );
      // box.values (unordered usually, but for test we return list)
      when(
        () => mockBox.values,
      ).thenReturn(historyList.map((e) => jsonEncode(e.toJson())).toList());

      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      when(() => mockBox.deleteAll(any())).thenAnswer((_) async {});

      // act
      await dataSource.saveHistory(tHistoryEntity); // Adds one more

      // assert
      // Logic: saveHistory calls put first, then checks total count.
      // Here we mocked values to be 501 strings.
      // getAllHistory sorts by playedAt descending.
      // Our generator: index 0 is oldest (time 0), index 500 is newest.
      // Sorted: 500, 499, ... 0.
      // If size > 500, we remove from 500 onwards.
      // In sorted list (length 501), index 500 is the oldest (id '0').
      // Wait, we returned 501 items. getAllHistory sorts them.
      // The new item is also added via put, but box.values in mock is static unless we update it.
      // But our implementation calls `put` then `getAllHistory`.
      // `getAllHistory` reads `box.values`.
      // So we should verify `deleteAll` is called with some keys.

      verify(() => mockBox.deleteAll(any())).called(1);
    });
  });

  group('deleteHistory', () {
    test('should delete from Box', () async {
      // arrange
      when(() => mockBox.delete('1')).thenAnswer((_) async {});

      // act
      await dataSource.deleteHistory('1');

      // assert
      verify(() => mockBox.delete('1')).called(1);
    });
  });

  group('clearAllHistory', () {
    test('should clear Box', () async {
      // arrange
      when(() => mockBox.clear()).thenAnswer((_) async => 0);

      // act
      await dataSource.clearAllHistory();

      // assert
      verify(() => mockBox.clear()).called(1);
    });
  });

  group('generateHistoryId', () {
    test('should increment counter', () async {
      // arrange
      when(
        () => mockBox.get('__history_counter__', defaultValue: 0),
      ).thenReturn(0);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      // act
      final result = await dataSource.generateHistoryId();

      // assert
      expect(result, 'history_1');
      verify(() => mockBox.put('__history_counter__', 1)).called(1);
    });
  });

  group('getHistoryByKey', () {
    test('should find history by key', () async {
      final jsonString = jsonEncode(tHistoryEntity.toJson());
      when(() => mockBox.values).thenReturn([jsonString]);

      final result = await dataSource.getHistoryByKey(
        surahId: 1,
        reciterId: '1',
        moshafId: 1,
      );

      expect(result?.id, tHistoryEntity.id);
    });
  });

  group('getHistoryCount', () {
    test('should return count of strings', () async {
      when(() => mockBox.values).thenReturn(['a', 'b', 123]); // 2 strings

      final result = await dataSource.getHistoryCount();

      expect(result, 2);
    });
  });

  group('saveAllHistory', () {
    test('should clear keys and put all', () async {
      when(() => mockBox.keys).thenReturn(['1', '2', '__history_counter__']);
      when(() => mockBox.deleteAll(any())).thenAnswer((_) async {});
      when(() => mockBox.putAll(any())).thenAnswer((_) async {});

      await dataSource.saveAllHistory([tHistoryEntity]);

      verify(() => mockBox.deleteAll(['1', '2'])).called(1);
      verify(() => mockBox.putAll(any())).called(1);
    });
  });
}
