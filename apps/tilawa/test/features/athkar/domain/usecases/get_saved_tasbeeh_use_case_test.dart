import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_saved_tasbeeh_use_case.dart';

import '../../helpers/fake_tasbeeh_repository.dart';

void main() {
  late FakeTasbeehRepository repository;
  late GetSavedTasbeehUseCase useCase;

  setUp(() {
    repository = FakeTasbeehRepository();
    useCase = GetSavedTasbeehUseCase(repository);
  });

  group('GetSavedTasbeehUseCase', () {
    test('returns empty list when no dhikr saved', () async {
      final result = await useCase(const NoParams());

      result.fold(
        (_) => fail('Expected Right result'),
        (items) => expect(items, isEmpty),
      );
    });

    test('returns all saved dhikr', () async {
      repository.seed(makeDhikr(id: '1', text: 'a'));
      repository.seed(makeDhikr(id: '2', text: 'b'));

      final result = await useCase(const NoParams());

      result.fold(
        (_) => fail('Expected Right result'),
        (items) => expect(items.map((d) => d.text), ['a', 'b']),
      );
    });

    test('propagates repository failure', () async {
      repository.shouldFail(const CacheFailure('storage broken'));

      final result = await useCase(const NoParams());

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, const CacheFailure('storage broken')),
        (_) => fail('Expected Left result'),
      );
    });
  });
}
