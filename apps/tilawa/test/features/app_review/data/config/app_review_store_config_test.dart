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
}
