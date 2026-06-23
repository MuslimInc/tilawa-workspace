import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../entities/session_lifecycle_status.dart';
import '../failures/quran_sessions_failure.dart';

abstract interface class SessionAggregateRepository {
  Future<Either<QuranSessionsFailure, SessionAggregate>> create(
    SessionAggregate aggregate,
  );

  Future<Either<QuranSessionsFailure, SessionAggregate>> getById(String id);

  Future<Either<QuranSessionsFailure, SessionAggregate>> save(
    SessionAggregate aggregate,
  );

  Future<Either<QuranSessionsFailure, List<SessionAggregate>>> listByStatus(
    SessionLifecycleStatus status, {
    DateTime? startsBefore,
  });
}
