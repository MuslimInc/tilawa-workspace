import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/data/config/app_review_store_config.dart';
import 'package:tilawa/features/app_review/data/datasources/app_review_platform_data_source.dart';
import 'package:tilawa/features/app_review/data/repositories/app_review_repository_impl.dart';
import 'package:tilawa_core/errors/failures.dart';

class _FakePlatform implements AppReviewPlatformDataSource {
  bool available = true;
  int requestCount = 0;
  int storeCount = 0;
  bool throwOnRequest = false;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requestCount++;
    if (throwOnRequest) {
      throw AppReviewFailure.requestFailed('platform');
    }
  }

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {
    storeCount++;
  }
}

void main() {
  late _FakePlatform platform;
  late AppReviewRepositoryImpl repository;

  setUp(() {
    platform = _FakePlatform();
    repository = AppReviewRepositoryImpl(
      platform,
      const AppReviewStoreConfig(appStoreId: '123'),
    );
  });

  test('isAvailable delegates to platform', () async {
    platform.available = false;
    expect(await repository.isAvailable(), isFalse);
  });

  test('requestReview throws when unavailable', () async {
    platform.available = false;
    expect(
      repository.requestReview,
      throwsA(isA<AppReviewFailure>()),
    );
  });

  test('requestReview delegates when available', () async {
    await repository.requestReview();
    expect(platform.requestCount, 1);
  });

  test('openStoreListing delegates to platform', () async {
    await repository.openStoreListing();
    expect(platform.storeCount, 1);
  });
}
