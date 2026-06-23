import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa/features/athkar/domain/usecases/delete_tasbeeh_dhikr_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_saved_tasbeeh_use_case.dart';

import '../../helpers/fake_tasbeeh_repository.dart';

void main() {
  late FakeTasbeehRepository repository;
  late DeleteTasbeehDhikrUseCase useCase;

  setUp(() {
    repository = FakeTasbeehRepository();
    useCase = DeleteTasbeehDhikrUseCase(repository);
  });

  group('DeleteTasbeehDhikrUseCase', () {
    test('removes existing dhikr from repository', () async {
      repository.seed(makeDhikr(id: '1'));
      repository.seed(makeDhikr(id: '2', text: 'keep me'));

      final result = await useCase('1');

      expect(result.isRight(), isTrue);

      final remaining = await GetSavedTasbeehUseCase(repository)(
        const NoParams(),
      );
      remaining.fold(
        (_) => fail('Expected Right result'),
        (items) {
          expect(items, hasLength(1));
          expect(items.single.id, '2');
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
