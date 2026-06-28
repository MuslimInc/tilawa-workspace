import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/session_aggregate_repository.dart';

class GetSessionAggregateUseCase {
  const GetSessionAggregateUseCase(this._repository);

  final SessionAggregateRepository _repository;

  Future<Either<QuranSessionsFailure, SessionAggregate>> call(
    String bookingId,
  ) => _repository.getById(bookingId);
}
