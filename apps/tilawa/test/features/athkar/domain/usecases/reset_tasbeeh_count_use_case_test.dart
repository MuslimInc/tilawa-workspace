import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/athkar/domain/usecases/reset_tasbeeh_count_use_case.dart';

import '../../helpers/fake_tasbeeh_repository.dart';

void main() {
  late FakeTasbeehRepository repository;
  late ResetTasbeehCountUseCase useCase;

  setUp(() {
    repository = FakeTasbeehRepository();
    useCase = ResetTasbeehCountUseCase(repository);
  });

  group('ResetTasbeehCountUseCase', () {
    test('resets count to zero and clears targetReachedNotified', () async {
      repository.seed(
        makeDhikr(id: '1', count: 99, targetReachedNotified: true),
      );

      final result = await useCase('1');

      result.fold(
        (_) => fail('Expected Right result'),
        (dhikr) {
          expect(dhikr.count, 0);
          expect(dhikr.targetReachedNotified, isFalse);
        },
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
  });
}
