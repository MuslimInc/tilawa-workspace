import 'package:injectable/injectable.dart';

import '../../domain/entities/forced_update_policy.dart';
import '../../domain/repositories/forced_update_repository.dart';
import '../datasources/forced_update_config_remote_data_source.dart';

@LazySingleton(as: ForcedUpdateRepository)
class ForcedUpdateRepositoryImpl implements ForcedUpdateRepository {
  const ForcedUpdateRepositoryImpl(this._configDataSource);

  final ForcedUpdateConfigRemoteDataSource _configDataSource;

  @override
  Future<ForcedUpdatePolicy> getPolicy() => _configDataSource.getPolicy();
}
