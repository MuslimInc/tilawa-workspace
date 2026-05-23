import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/repositories/app_review_repository.dart';
import '../config/app_review_store_config.dart';
import '../datasources/app_review_platform_data_source.dart';

@LazySingleton(as: AppReviewRepository)
class AppReviewRepositoryImpl implements AppReviewRepository {
  AppReviewRepositoryImpl(
    this._platform,
    this._storeConfig,
  );

  final AppReviewPlatformDataSource _platform;
  final AppReviewStoreConfig _storeConfig;

  @override
  Future<bool> isAvailable() => _platform.isAvailable();

  @override
  Future<void> requestReview() async {
    final bool available = await _platform.isAvailable();
    if (!available) {
      throw const AppReviewFailure.unavailable();
    }
    await _platform.requestReview();
  }

  @override
  Future<void> openStoreListing() => _platform.openStoreListing(
    appStoreId: _storeConfig.appStoreIdOrNull,
    microsoftStoreId: _storeConfig.microsoftStoreIdOrNull,
  );
}
