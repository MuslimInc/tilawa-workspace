import 'package:injectable/injectable.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../../domain/entities/in_app_update_availability.dart';
import '../../domain/entities/in_app_update_policy.dart';
import '../../domain/repositories/in_app_update_repository.dart';
import '../datasources/in_app_update_config_remote_data_source.dart';
import '../datasources/in_app_update_platform_data_source.dart';

@LazySingleton(as: InAppUpdateRepository)
class InAppUpdateRepositoryImpl implements InAppUpdateRepository {
  const InAppUpdateRepositoryImpl(
    this._configDataSource,
    this._platformDataSource,
  );

  final InAppUpdateConfigRemoteDataSource _configDataSource;
  final InAppUpdatePlatformDataSource _platformDataSource;

  @override
  Future<bool> isSupported() => _platformDataSource.isSupported();

  @override
  Future<InAppUpdatePolicy> getPolicy() => _configDataSource.getPolicy();

  @override
  ResultFuture<InAppUpdateAvailability> checkAvailability() =>
      _platformDataSource.checkAvailability();

  @override
  ResultFuture<void> performImmediateUpdate() =>
      _platformDataSource.performImmediateUpdate();

  @override
  ResultFuture<void> openAppStoreListing() =>
      _platformDataSource.openAppStoreListing();

  @override
  ResultFuture<bool> startFlexibleUpdate() =>
      _platformDataSource.startFlexibleUpdate();

  @override
  ResultFuture<void> completeFlexibleUpdate() =>
      _platformDataSource.completeFlexibleUpdate();
}
