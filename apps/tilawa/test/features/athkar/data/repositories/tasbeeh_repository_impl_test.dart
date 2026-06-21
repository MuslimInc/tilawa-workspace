import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/data/datasources/tasbeeh_local_datasource.dart';
import 'package:tilawa/features/athkar/data/models/tasbeeh_dhikr_model.dart';
import 'package:tilawa/features/athkar/data/repositories/tasbeeh_repository_impl.dart';
import 'package:tilawa_core/errors/failures.dart';

class _InMemoryTasbeehLocalDataSource implements TasbeehLocalDataSource {
  final Map<String, TasbeehDhikrModel> _store = {};

  @override
  Future<List<TasbeehDhikrModel>> getAllDhikr() async {
    final items = _store.values.toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<TasbeehDhikrModel?> getDhikrById(String id) async {
    return _store[id];
  }

  @override
  Future<void> saveDhikr(TasbeehDhikrModel model) async {
    _store[model.id] = model;
  }

  @override
  Future<void> deleteDhikr(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> deleteAllDhikr() async {
    _store.clear();
  }
}

void main() {
  late TasbeehRepositoryImpl repository;
  late _InMemoryTasbeehLocalDataSource dataSource;

  setUp(() {
    dataSource = _InMemoryTasbeehLocalDataSource();
    repository = TasbeehRepositoryImpl(dataSource);
  });

  test('saveCustomDhikr saves a new item with count=0', () async {
    final result = await repository.saveCustomDhikr(
      text: 'Subhan Allah',
      targetCount: 33,
    );

    expect(result.isRight(), true);
    result.fold((_) => fail('Expected Right result'), (item) {
      expect(item.text, 'Subhan Allah');
      expect(item.count, 0);
      expect(item.targetCount, 33);
      expect(item.targetReachedNotified, false);
    });
  });

  test('saveCustomDhikr rejects empty text', () async {
    final result = await repository.saveCustomDhikr(
      text: '   ',
      targetCount: 33,
    );

    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('Expected Left result'),
    );
  });

  test('incrementCount increments selected saved dhikr', () async {
    final saved = await repository.saveCustomDhikr(
      text: 'Alhamdulillah',
      targetCount: 2,
    );
    final id = saved
        .getOrElse(() => throw StateError('expected save to succeed'))
        .id;

    final result = await repository.incrementCount(id);

    expect(result.isRight(), true);
    result.fold((_) => fail('Expected Right result'), (item) {
      expect(item.count, 1);
      expect(item.targetReachedNotified, false);
    });
  });

  test('resetCount sets count to zero', () async {
    final saved = await repository.saveCustomDhikr(
      text: 'Allahu Akbar',
      targetCount: 2,
    );
    final id = saved
        .getOrElse(() => throw StateError('expected save to succeed'))
        .id;

    await repository.incrementCount(id);
    await repository.incrementCount(id);

    final result = await repository.resetCount(id);

    expect(result.isRight(), true);
    result.fold((_) => fail('Expected Right result'), (item) {
      expect(item.count, 0);
      expect(item.targetReachedNotified, false);
    });
  });

  test(
    'incrementCount marks target reached once when crossing target',
    () async {
      final saved = await repository.saveCustomDhikr(
        text: 'Target test',
        targetCount: 1,
      );
      final id = saved
          .getOrElse(() => throw StateError('expected save to succeed'))
          .id;

      final first = await repository.incrementCount(id);
      final second = await repository.incrementCount(id);

      first.fold(
        (_) => fail('Expected first increment to succeed'),
        (item) => expect(item.targetReachedNotified, true),
      );
      second.fold(
        (_) => fail('Expected second increment to succeed'),
        (item) => expect(item.targetReachedNotified, true),
      );
    },
  );

  test('setTargetCount persists updated target value', () async {
    final saved = await repository.saveCustomDhikr(
      text: 'Set target',
      targetCount: 33,
    );
    final id = saved
        .getOrElse(() => throw StateError('expected save to succeed'))
        .id;

    final result = await repository.setTargetCount(dhikrId: id, targetCount: 7);

    expect(result.isRight(), true);
    result.fold(
      (_) => fail('Expected Right result'),
      (item) => expect(item.targetCount, 7),
    );
  });

  test('deleteDhikr removes the item from local history', () async {
    final saved = await repository.saveCustomDhikr(
      text: 'Delete me',
      targetCount: 10,
    );
    final id = saved
        .getOrElse(() => throw StateError('expected save to succeed'))
        .id;

    final deleteResult = await repository.deleteDhikr(id);
    final all = await repository.getSavedDhikr();

    expect(deleteResult.isRight(), true);
    all.fold(
      (_) => fail('Expected items list to load'),
      (items) => expect(items.where((e) => e.id == id), isEmpty),
    );
  });
}
