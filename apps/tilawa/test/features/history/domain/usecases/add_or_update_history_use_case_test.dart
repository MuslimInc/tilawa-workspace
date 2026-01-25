import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/history/domain/usecases/add_or_update_history_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late AddOrUpdateHistoryUseCase useCase;
  late MockHistoryRepository mockRepository;

  setUp(() {
    mockRepository = MockHistoryRepository();
    useCase = AddOrUpdateHistoryUseCase(mockRepository);
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

  test(
    'should call addOrUpdateHistory on repository and return HistoryEntity',
    () async {
      // arrange
      when(
        () => mockRepository.addOrUpdateHistory(
          surahId: any(named: 'surahId'),
          surahName: any(named: 'surahName'),
          surahNameEn: any(named: 'surahNameEn'),
          reciterId: any(named: 'reciterId'),
          reciterName: any(named: 'reciterName'),
          moshafId: any(named: 'moshafId'),
          moshafName: any(named: 'moshafName'),
          lastPositionMs: any(named: 'lastPositionMs'),
          durationMs: any(named: 'durationMs'),
          audioUrl: any(named: 'audioUrl'),
        ),
      ).thenAnswer((_) async => tHistoryEntity);

      // act
      final result = await useCase.call(
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
      );

      // assert
      expect(result, Right<Failure, HistoryEntity>(tHistoryEntity));
      verify(
        () => mockRepository.addOrUpdateHistory(
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
        ),
      ).called(1);
    },
  );

  test('should return CacheFailure when repository throws exception', () async {
    // arrange
    when(
      () => mockRepository.addOrUpdateHistory(
        surahId: any(named: 'surahId'),
        surahName: any(named: 'surahName'),
        surahNameEn: any(named: 'surahNameEn'),
        reciterId: any(named: 'reciterId'),
        reciterName: any(named: 'reciterName'),
        moshafId: any(named: 'moshafId'),
        moshafName: any(named: 'moshafName'),
        lastPositionMs: any(named: 'lastPositionMs'),
        durationMs: any(named: 'durationMs'),
        audioUrl: any(named: 'audioUrl'),
      ),
    ).thenThrow(Exception('Error'));

    // act
    final result = await useCase.call(
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
    );

    // assert
    expect(result, isA<Left<Failure, HistoryEntity>>());
  });
}
