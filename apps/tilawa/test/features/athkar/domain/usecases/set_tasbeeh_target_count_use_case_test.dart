import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/athkar/domain/usecases/set_tasbeeh_target_count_use_case.dart';

import '../../helpers/fake_tasbeeh_repository.dart';

void main() {
  late FakeTasbeehRepository repository;
  late SetTasbeehTargetCountUseCase useCase;

  setUp(() {
    repository = FakeTasbeehRepository();
    useCase = SetTasbeehTargetCountUseCase(repository);
  });

  group('SetTasbeehTargetCountUseCase', () {
    test('updates targetCount on existing dhikr', () async {
      repository.seed(makeDhikr(id: '1', targetCount: 33));

      final result = await useCase(
        const SetTasbeehTargetCountParams(dhikrId: '1', targetCount: 100),
      );

      result.fold(
        (_) => fail('Expected Right result'),
        (dhikr) => expect(dhikr.targetCount, 100),
      );
    });

    test('returns CacheFailure when dhikr id does not exist', () async {
      final result = await useCase(
        const SetTasbeehTargetCountParams(
          dhikrId: 'missing',
          targetCount: 99,
        ),
      );

      expect(result.isLeft, isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left result'),
      );
    });
  });
}
