import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/features/athkar/domain/entities/tasbeeh_dhikr.dart';
import 'package:tilawa/features/athkar/domain/repositories/tasbeeh_repository.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

/// In-memory [TasbeehRepository] for use-case tests.
///
/// Behaves like a real repository: keeps items keyed by id, mutates them in
/// place, and reports [CacheFailure] for ids that don't exist. Use
/// [seed] to preload state for a test, and [shouldFail] to force a
/// failure on the next mutating call.
class FakeTasbeehRepository implements TasbeehRepository {
  final Map<String, TasbeehDhikr> _items = {};
  int _nextId = 1;
  Failure? _nextFailure;

  void seed(TasbeehDhikr dhikr) => _items[dhikr.id] = dhikr;

  void shouldFail(Failure failure) => _nextFailure = failure;

  Failure? _consumeFailure() {
    final f = _nextFailure;
    _nextFailure = null;
    return f;
  }

  @override
  ResultFuture<List<TasbeehDhikr>> getSavedDhikr() async {
    final f = _consumeFailure();
    if (f != null) return Left(f);
    return Right(_items.values.toList());
  }

  @override
  ResultFuture<TasbeehDhikr> saveCustomDhikr({
    required String text,
    required int targetCount,
  }) async {
    final f = _consumeFailure();
    if (f != null) return Left(f);
    final item = TasbeehDhikr(
      id: '${_nextId++}',
      text: text,
      count: 0,
      targetCount: targetCount,
      targetReachedNotified: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    _items[item.id] = item;
    return Right(item);
  }

  @override
  ResultFuture<TasbeehDhikr> incrementCount(String dhikrId) async {
    final f = _consumeFailure();
    if (f != null) return Left(f);
    final current = _items[dhikrId];
    if (current == null) {
      return const Left(CacheFailure('dhikr not found'));
    }
    final updated = current.copyWith(
      count: current.count + 1,
      updatedAt: DateTime(2026, 1, 2),
    );
    _items[dhikrId] = updated;
    return Right(updated);
  }

  @override
  ResultFuture<TasbeehDhikr> resetCount(String dhikrId) async {
    final f = _consumeFailure();
    if (f != null) return Left(f);
    final current = _items[dhikrId];
    if (current == null) {
      return const Left(CacheFailure('dhikr not found'));
    }
    final updated = current.copyWith(
      count: 0,
      targetReachedNotified: false,
      updatedAt: DateTime(2026, 1, 2),
    );
    _items[dhikrId] = updated;
    return Right(updated);
  }

  @override
  ResultFuture<TasbeehDhikr> setTargetCount({
    required String dhikrId,
    required int targetCount,
  }) async {
    final f = _consumeFailure();
    if (f != null) return Left(f);
    final current = _items[dhikrId];
    if (current == null) {
      return const Left(CacheFailure('dhikr not found'));
    }
    final updated = current.copyWith(
      targetCount: targetCount,
      updatedAt: DateTime(2026, 1, 2),
    );
    _items[dhikrId] = updated;
    return Right(updated);
  }

  @override
  ResultVoid deleteDhikr(String dhikrId) async {
    final f = _consumeFailure();
    if (f != null) return Left(f);
    if (!_items.containsKey(dhikrId)) {
      return const Left(CacheFailure('dhikr not found'));
    }
    _items.remove(dhikrId);
    return const Right(null);
  }

  @override
  ResultVoid deleteAllDhikr() async {
    final f = _consumeFailure();
    if (f != null) return Left(f);
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
    final f = _consumeFailure();
    if (f != null) return Left(f);
    final current = _items[dhikrId];
    if (current == null) {
      return const Left(CacheFailure('dhikr not found'));
    }
    final updated = current.copyWith(
      reminderEnabled: enabled,
      reminderHour: enabled ? hour : null,
      reminderMinute: enabled ? minute : null,
      updatedAt: DateTime(2026, 1, 3),
    );
    _items[dhikrId] = updated;
    return Right(updated);
  }
}

TasbeehDhikr makeDhikr({
  String id = '1',
  String text = 'Subhan Allah',
  int count = 0,
  int targetCount = 33,
  bool targetReachedNotified = false,
}) {
  return TasbeehDhikr(
    id: id,
    text: text,
    count: count,
    targetCount: targetCount,
    targetReachedNotified: targetReachedNotified,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}
