import 'package:injectable/injectable.dart';

import 'token_sync_cache.dart';

/// Reads the locally cached session epoch for Quran Sessions callables.
abstract class SessionEpochProvider {
  Future<int> getSessionEpoch();
}

@LazySingleton(as: SessionEpochProvider)
class SessionEpochProviderImpl implements SessionEpochProvider {
  SessionEpochProviderImpl(this._tokenSyncCache);

  final TokenSyncCache _tokenSyncCache;

  @override
  Future<int> getSessionEpoch() async =>
      await _tokenSyncCache.getSessionEpoch() ?? 0;
}
