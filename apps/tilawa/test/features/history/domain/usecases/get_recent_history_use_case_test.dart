import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/history/domain/usecases/get_recent_history_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late GetRecentHistoryUseCase useCase;
  late MockHistoryRepository mockRepository;

  setUp(() {
    mockRepository = MockHistoryRepository();
    useCase = GetRecentHistoryUseCase(mockRepository);
  });

  final tHistory = [
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
      playedAt: DateTime.now(),
    ),
  ];

  test('should get recent history from repository', () async {
    // arrange
    when(
      () => mockRepository.getRecentHistory(limit: any(named: 'limit')),
    ).thenAnswer((_) async => tHistory);

    // act
    final result = await useCase.call(limit: 5);

    // assert
    expect(result, Right<Failure, List<HistoryEntity>>(tHistory));
    verify(() => mockRepository.getRecentHistory(limit: 5)).called(1);
  });

  test('should return CacheFailure on exception', () async {
    // arrange
    when(
      () => mockRepository.getRecentHistory(limit: any(named: 'limit')),
    ).thenThrow(Exception());

    // act
    final result = await useCase.call(limit: 5);

    // assert
    expect(result, isA<Left<Failure, List<HistoryEntity>>>());
  });
}
