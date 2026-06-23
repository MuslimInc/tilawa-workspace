import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

class FakeSessionAggregateRepository implements SessionAggregateRepository {
  final Map<String, SessionAggregate> store = {};
  QuranSessionsFailure? failWith;

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> create(
    SessionAggregate aggregate,
  ) async {
    if (failWith != null) return Left(failWith!);
    store[aggregate.id] = aggregate;
    return Right(aggregate);
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> getById(
    String id,
  ) async {
    if (failWith != null) return Left(failWith!);
    final aggregate = store[id];
    if (aggregate == null) {
      return const Left(NotFoundFailure('SessionAggregate'));
    }
    return Right(aggregate);
  }

  @override
  Future<Either<QuranSessionsFailure, List<SessionAggregate>>> listByStatus(
    SessionLifecycleStatus status, {
    DateTime? startsBefore,
  }) async {
    if (failWith != null) return Left(failWith!);
    final rows = store.values
        .where((aggregate) {
          if (aggregate.lifecycleStatus != status) return false;
          return startsBefore == null ||
              !aggregate.startsAt.isAfter(startsBefore);
        })
        .toList(growable: false);
    return Right(rows);
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> save(
    SessionAggregate aggregate,
  ) async {
    if (failWith != null) return Left(failWith!);
    store[aggregate.id] = aggregate;
    return Right(aggregate);
  }
}
