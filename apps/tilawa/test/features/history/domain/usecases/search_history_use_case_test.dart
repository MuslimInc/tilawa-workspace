import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/history/domain/usecases/search_history_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late SearchHistoryUseCase useCase;
  late MockHistoryRepository mockRepository;

  setUp(() {
    mockRepository = MockHistoryRepository();
    useCase = SearchHistoryUseCase(mockRepository);
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
  const tQuery = 'test';

  test('should search history from repository', () async {
    // arrange
    when(
      () => mockRepository.searchHistory(tQuery),
    ).thenAnswer((_) async => tHistory);

    // act
    final result = await useCase.call(tQuery);

    // assert
    expect(result, Right<Failure, List<HistoryEntity>>(tHistory));
    verify(() => mockRepository.searchHistory(tQuery)).called(1);
  });

  test('should return CacheFailure on exception', () async {
    // arrange
    when(() => mockRepository.searchHistory(tQuery)).thenThrow(Exception());

    // act
    final result = await useCase.call(tQuery);

    // assert
    expect(result, isA<Left<Failure, List<HistoryEntity>>>());
  });
}
