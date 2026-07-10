import 'package:tilawa/core/logging/app_logger.dart';

import '../domain/entities/quran_sessions_platform_config.dart';
import '../quran_sessions_platform_config_store.dart';
import 'firebase/firestore_platform_config_data_source.dart';
import 'local/shared_preferences_platform_config_data_source.dart';

class QuranSessionsPlatformConfigRepository {
  QuranSessionsPlatformConfigRepository({
    required this._remoteDataSource,
    required this._localDataSource,
    required this._store,
  });

  final FirestorePlatformConfigDataSource? _remoteDataSource;
  final SharedPreferencesPlatformConfigDataSource _localDataSource;
  final QuranSessionsPlatformConfigStore _store;

  Future<void> loadCachedConfig() async {
    try {
      _store.setConfig(await _localDataSource.load());
    } catch (e, st) {
      logger.w(
        '[QuranSessionsPlatformConfig] cache load failed: $e',
        stackTrace: st,
      );
      _store.setConfig(null);
    }
  }

  Future<QuranSessionsPlatformConfig?> refreshRemoteConfig() async {
    final remoteDataSource = _remoteDataSource;
    if (remoteDataSource == null) {
      return _store.config;
    }
    try {
      final config = await remoteDataSource.getGlobalConfig();
      _store.setConfig(config);
      if (config != null) {
        await _localDataSource.save(config);
      } else {
        await _localDataSource.clear();
      }
      return config;
    } catch (e, st) {
      logger.w(
        '[QuranSessionsPlatformConfig] remote refresh failed: $e',
        stackTrace: st,
      );
      return _store.config;
    }
  }
}
