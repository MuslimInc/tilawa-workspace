import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/history/domain/usecases/clear_all_history_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late ClearAllHistoryUseCase useCase;
  late MockHistoryRepository mockRepository;

  setUp(() {
    mockRepository = MockHistoryRepository();
    useCase = ClearAllHistoryUseCase(mockRepository);
  });

  test('should call deleteAllHistory on repository', () async {
    // arrange
    when(() => mockRepository.deleteAllHistory()).thenAnswer((_) async {});

    // act
    final result = await useCase.call();

    // assert
    expect(result, const Right<Failure, void>(null));
    verify(() => mockRepository.deleteAllHistory()).called(1);
  });

  test('should return CacheFailure on exception', () async {
    // arrange
    when(() => mockRepository.deleteAllHistory()).thenThrow(Exception());

    // act
    final result = await useCase.call();

    // assert
    expect(result, isA<Left<Failure, void>>());
  });
}
