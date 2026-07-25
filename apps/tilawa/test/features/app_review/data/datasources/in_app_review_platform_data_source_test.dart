import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/app_review/data/config/app_review_store_config.dart';
import 'package:tilawa/features/app_review/data/datasources/in_app_review_platform_data_source.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockInAppReview extends Mock implements InAppReview {}

void main() {
  late MockInAppReview review;
  late List<Uri> launchedUris;
  late InAppReviewPlatformDataSource dataSource;

  setUp(() {
    review = MockInAppReview();
    launchedUris = <Uri>[];
    dataSource = InAppReviewPlatformDataSource(
      review,
      launchUrlFn: (Uri uri) async {
        launchedUris.add(uri);
        return true;
      },
    );
  });

  test('isAvailable returns platform value', () async {
    when(() => review.isAvailable()).thenAnswer((_) async => true);
    expect(await dataSource.isAvailable(), isTrue);
  });

  test('isAvailable returns false when platform throws', () async {
    when(() => review.isAvailable()).thenThrow(Exception('network'));
    expect(await dataSource.isAvailable(), isFalse);
  });

  test('requestReview completes when platform succeeds', () async {
    when(() => review.requestReview()).thenAnswer((_) async {});
    await expectLater(dataSource.requestReview(), completes);
  });

  test('requestReview throws AppReviewFailure when platform fails', () async {
    when(() => review.requestReview()).thenThrow(Exception('quota'));
    expect(
      dataSource.requestReview,
      throwsA(isA<AppReviewFailure>()),
    );
  });

  test('openStoreListing on Android opens production Play URL', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await dataSource.openStoreListing(
      androidPackageId: AppReviewStoreConfig.kProductionAndroidPackageId,
      writeReview: true,
    );

    expect(launchedUris, hasLength(1));
    expect(
      launchedUris.single.toString(),
      'https://play.google.com/store/apps/details?id=com.tilawa.app',
    );
  });

  test(
    'openStoreListing on iOS opens write-review URL when requested',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await dataSource.openStoreListing(
        appStoreId: AppReviewStoreConfig.kProductionAppStoreId,
        writeReview: true,
      );

      expect(launchedUris, hasLength(1));
      expect(
        launchedUris.single.toString(),
        'https://apps.apple.com/app/id6791827426?action=write-review',
      );
    },
  );

  test(
    'openStoreListing on iOS opens listing URL without write-review',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await dataSource.openStoreListing(
        appStoreId: AppReviewStoreConfig.kProductionAppStoreId,
      );

      expect(launchedUris, hasLength(1));
      expect(
        launchedUris.single.toString(),
        'https://apps.apple.com/app/id6791827426',
      );
    },
  );

  test('openStoreListing throws when Android launch fails', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final failing = InAppReviewPlatformDataSource(
      review,
      launchUrlFn: (_) async => false,
    );

    expect(
      () => failing.openStoreListing(
        androidPackageId: AppReviewStoreConfig.kProductionAndroidPackageId,
      ),
      throwsA(isA<AppReviewFailure>()),
    );
  });

  test('openStoreListing throws when iOS launch fails', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final failing = InAppReviewPlatformDataSource(
      review,
      launchUrlFn: (_) async => false,
    );

    expect(
      () => failing.openStoreListing(
        appStoreId: AppReviewStoreConfig.kProductionAppStoreId,
        writeReview: true,
      ),
      throwsA(isA<AppReviewFailure>()),
    );
  });

  test('openStoreListing throws on unsupported platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(
      dataSource.openStoreListing,
      throwsA(
        isA<AppReviewFailure>().having(
          (AppReviewFailure f) => f.reason,
          'reason',
          AppReviewFailureReason.platformUnsupported,
        ),
      ),
    );
  });
}
