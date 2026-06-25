import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../cache/quran_session_cache_store.dart';
import '../cache/session_cache_key.dart';
import 'get_session_detail_usecase.dart';

class RefreshSessionDetailUseCase {
  const RefreshSessionDetailUseCase({
    required this.getSessionDetail,
    required this.cacheStore,
  });

  final GetSessionDetailUseCase getSessionDetail;
  final QuranSessionCacheStore cacheStore;

  Future<Either<QuranSessionsFailure, QuranSession>> call(
    String sessionId,
  ) async {
    cacheStore.remove(SessionCacheKey.sessionDetail(sessionId));
    return getSessionDetail(sessionId);
  }
}
