import 'package:injectable/injectable.dart';

import '../../domain/repositories/whats_new_progress_repository.dart';
import '../datasources/whats_new_progress_local_data_source.dart';

@LazySingleton(as: WhatsNewProgressRepository)
class WhatsNewProgressRepositoryImpl implements WhatsNewProgressRepository {
  WhatsNewProgressRepositoryImpl(this._localDataSource);

  final WhatsNewProgressLocalDataSource _localDataSource;

  @override
  Future<String?> getLastSeenReleaseId() {
    return _localDataSource.readLastSeenReleaseId();
  }

  @override
  Future<void> markReleaseSeen(String releaseId) {
    return _localDataSource.writeLastSeenReleaseId(releaseId);
  }

  @override
  Future<void> clearProgress() {
    return _localDataSource.clear();
  }
}
