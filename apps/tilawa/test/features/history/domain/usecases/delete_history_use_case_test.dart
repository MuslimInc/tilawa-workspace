import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/history/domain/usecases/delete_history_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late DeleteHistoryUseCase useCase;
  late MockHistoryRepository mockRepository;

  setUp(() {
    mockRepository = MockHistoryRepository();
    useCase = DeleteHistoryUseCase(mockRepository);
  });

  const tId = '1';

  test('should call deleteHistory on repository', () async {
    // arrange
    when(() => mockRepository.deleteHistory(tId)).thenAnswer((_) async {});

    // act
    final result = await useCase.call(tId);

    // assert
    expect(result, const Right<Failure, void>(null));
    verify(() => mockRepository.deleteHistory(tId)).called(1);
  });

  test('should return CacheFailure on exception', () async {
    // arrange
    when(() => mockRepository.deleteHistory(tId)).thenThrow(Exception());

    // act
    final result = await useCase.call(tId);

    // assert
    expect(result, isA<Left<Failure, void>>());
  });
}
