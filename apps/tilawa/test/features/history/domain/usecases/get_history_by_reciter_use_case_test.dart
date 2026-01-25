import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/history/domain/usecases/get_history_by_reciter_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late GetHistoryByReciterUseCase useCase;
  late MockHistoryRepository mockRepository;

  setUp(() {
    mockRepository = MockHistoryRepository();
    useCase = GetHistoryByReciterUseCase(mockRepository);
  });

  final tHistory = [
    HistoryEntity(
      id: '1',
      surahId: 1,
      surahName: '',
      surahNameEn: '',
      reciterId: '1',
      reciterName: '',
      moshafId: 1,
      moshafName: '',
      lastPositionMs: 0,
      durationMs: 0,
      audioUrl: '',
      playedAt: DateTime.now(),
    ),
  ];

  const tReciterId = '1';

  test('should get history by reciter from repository', () async {
    // arrange
    when(
      () => mockRepository.getHistoryByReciter(tReciterId),
    ).thenAnswer((_) async => tHistory);

    // act
    final result = await useCase.call(tReciterId);

    // assert
    expect(result, Right<Failure, List<HistoryEntity>>(tHistory));
    verify(() => mockRepository.getHistoryByReciter(tReciterId)).called(1);
  });

  test('should return CacheFailure on exception', () async {
    // arrange
    when(
      () => mockRepository.getHistoryByReciter(tReciterId),
    ).thenThrow(Exception());

    // act
    final result = await useCase.call(tReciterId);

    // assert
    expect(result, isA<Left<Failure, List<HistoryEntity>>>());
  });
}
