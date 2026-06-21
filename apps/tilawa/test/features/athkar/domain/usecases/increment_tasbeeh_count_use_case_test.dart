import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/athkar/domain/usecases/increment_tasbeeh_count_use_case.dart';

import '../../helpers/fake_tasbeeh_repository.dart';

void main() {
  late FakeTasbeehRepository repository;
  late IncrementTasbeehCountUseCase useCase;

  setUp(() {
    repository = FakeTasbeehRepository();
    useCase = IncrementTasbeehCountUseCase(repository);
  });

  group('IncrementTasbeehCountUseCase', () {
    test('increments count by one and returns updated dhikr', () async {
      repository.seed(makeDhikr(id: '1', count: 4));

      final result = await useCase('1');

      result.fold(
        (_) => fail('Expected Right result'),
        (dhikr) => expect(dhikr.count, 5),
      );
    });

    test('returns CacheFailure when dhikr id does not exist', () async {
      final result = await useCase('missing');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left result'),
      );
    });

    test('propagates an explicit repository failure', () async {
      repository.seed(makeDhikr(id: '1'));
      repository.shouldFail(const CacheFailure('write failed'));

      final result = await useCase('1');

      result.fold(
        (f) => expect(f, const CacheFailure('write failed')),
        (_) => fail('Expected Left result'),
      );
    });
  });
}
