import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/domain/entities/tasbeeh_dhikr.dart';
import 'package:tilawa/features/athkar/domain/repositories/tasbeeh_repository.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_saved_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/save_custom_tasbeeh_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';

class _FakeTasbeehRepository implements TasbeehRepository {
  final List<TasbeehDhikr> _items = [];

  @override
  ResultFuture<List<TasbeehDhikr>> getSavedDhikr() async => Right(_items);

  @override
  ResultFuture<TasbeehDhikr> incrementCount(String dhikrId) async {
    return const Left(CacheFailure('not needed in this test'));
  }

  @override
  ResultFuture<TasbeehDhikr> resetCount(String dhikrId) async {
    return const Left(CacheFailure('not needed in this test'));
  }

  @override
  ResultFuture<TasbeehDhikr> saveCustomDhikr({
    required String text,
    required int targetCount,
  }) async {
    final item = TasbeehDhikr(
      id: (_items.length + 1).toString(),
      text: text,
      count: 0,
      targetCount: targetCount,
      targetReachedNotified: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    _items.add(item);
    return Right(item);
  }

  @override
  ResultFuture<TasbeehDhikr> setTargetCount({
    required String dhikrId,
    required int targetCount,
  }) async {
    return const Left(CacheFailure('not needed in this test'));
  }

  @override
  ResultVoid deleteDhikr(String dhikrId) async {
    return const Right(null);
  }

  @override
  ResultVoid deleteAllDhikr() async {
    _items.clear();
    return const Right(null);
  }

  @override
  ResultFuture<TasbeehDhikr> setReminder({
    required String dhikrId,
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    return const Left(CacheFailure('not needed in this test'));
  }
}

void main() {
  late _FakeTasbeehRepository repository;

  setUp(() {
    repository = _FakeTasbeehRepository();
  });

  test('SaveCustomTasbeehUseCase saves a dhikr', () async {
    final useCase = SaveCustomTasbeehUseCase(repository);
    final result = await useCase(
      const SaveCustomTasbeehParams(
        text: 'La ilaha illa Allah',
        targetCount: 99,
      ),
    );

    expect(result.isRight(), true);
    result.fold((_) => fail('Expected Right result'), (item) {
      expect(item.text, 'La ilaha illa Allah');
      expect(item.targetCount, 99);
    });
  });

  test('GetSavedTasbeehUseCase returns saved items', () async {
    final saveUseCase = SaveCustomTasbeehUseCase(repository);
    final getUseCase = GetSavedTasbeehUseCase(repository);

    await saveUseCase(
      const SaveCustomTasbeehParams(text: 'Subhan Allah', targetCount: 33),
    );
    final result = await getUseCase(const NoParams());

    expect(result.isRight(), true);
    result.fold(
      (_) => fail('Expected Right result'),
      (items) => expect(items.length, 1),
    );
  });
}
