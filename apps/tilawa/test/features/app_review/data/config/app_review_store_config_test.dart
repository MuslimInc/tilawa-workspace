import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/data/config/app_review_store_config.dart';

void main() {
  test('appStoreIdOrNull is null when id is empty', () {
    const AppReviewStoreConfig config = AppReviewStoreConfig(appStoreId: '');
    expect(config.appStoreIdOrNull, isNull);
  });

  test('appStoreIdOrNull returns id when set', () {
    const AppReviewStoreConfig config = AppReviewStoreConfig(
      appStoreId: '12345',
    );
    expect(config.appStoreIdOrNull, '12345');
  });

  test('microsoftStoreIdOrNull is null when id is empty', () {
    const AppReviewStoreConfig config = AppReviewStoreConfig(
      microsoftStoreId: '',
    );
    expect(config.microsoftStoreIdOrNull, isNull);
  });

  test('default appStoreId uses production App Store id', () {
    const AppReviewStoreConfig config = AppReviewStoreConfig();
    expect(config.appStoreId, AppReviewStoreConfig.kProductionAppStoreId);
  });

  test('appStoreListingUri uses production App Store id by default', () {
    const AppReviewStoreConfig config = AppReviewStoreConfig();
    expect(
      config.appStoreListingUri.toString(),
      'https://apps.apple.com/app/id${AppReviewStoreConfig.kProductionAppStoreId}',
    );
    expect(config.appStoreListingUri.path, isNot(contains('/us/')));
  });

  test('appStoreListingUriFor falls back when id is empty', () {
    expect(
      AppReviewStoreConfig.appStoreListingUriFor('').toString(),
      'https://apps.apple.com/app/id${AppReviewStoreConfig.kProductionAppStoreId}',
    );
  });

  test('appStoreWriteReviewUri uses production write-review URL', () {
    const AppReviewStoreConfig config = AppReviewStoreConfig();
    expect(
      config.appStoreWriteReviewUri.toString(),
      'https://apps.apple.com/app/id6791827426?action=write-review',
    );
  });

  test('appStoreWriteReviewUriFor falls back when id is empty', () {
    expect(
      AppReviewStoreConfig.appStoreWriteReviewUriFor('').toString(),
      'https://apps.apple.com/app/id6791827426?action=write-review',
    );
  });

  test('playStoreListingUri uses production android package by default', () {
    const AppReviewStoreConfig config = AppReviewStoreConfig();
    expect(
      config.playStoreListingUri.toString(),
      'https://play.google.com/store/apps/details?id=com.tilawa.app',
    );
  });

  test('playStoreListingUriFor falls back when package id is empty', () {
    expect(
      AppReviewStoreConfig.playStoreListingUriFor('').toString(),
      'https://play.google.com/store/apps/details?id=com.tilawa.app',
    );
  });
}
