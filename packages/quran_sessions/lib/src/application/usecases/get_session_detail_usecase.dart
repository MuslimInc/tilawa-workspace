import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../cache/cache_freshness_policy.dart';
import '../cache/quran_session_cache_store.dart';
import '../cache/session_cache_key.dart';
import '../../domain/repositories/session_repository.dart';

class GetSessionDetailUseCase {
  const GetSessionDetailUseCase({
    required this.sessionRepository,
    required this.cacheStore,
  });

  final SessionRepository sessionRepository;
  final QuranSessionCacheStore cacheStore;

  Future<Either<QuranSessionsFailure, QuranSession>> call(
    String sessionId,
  ) async {
    try {
      final session = await cacheStore.getOrFetch<QuranSession>(
        key: SessionCacheKey.sessionDetail(sessionId),
        ttl: CacheFreshnessPolicy.sessionDetailTtl,
        fetcher: () async {
          final res = await sessionRepository.getSessionById(sessionId);
          return res.fold((f) => throw f, (s) => s);
        },
      );
      return Right(session);
    } on QuranSessionsFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }
}
