import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/app_review/data/datasources/in_app_review_platform_data_source.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockInAppReview extends Mock implements InAppReview {}

void main() {
  late MockInAppReview review;
  late InAppReviewPlatformDataSource dataSource;

  setUp(() {
    review = MockInAppReview();
    dataSource = InAppReviewPlatformDataSource(review);
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

  test('openStoreListing delegates to platform', () async {
    when(
      () => review.openStoreListing(
        appStoreId: any(named: 'appStoreId'),
        microsoftStoreId: any(named: 'microsoftStoreId'),
      ),
    ).thenAnswer((_) async {});
    await dataSource.openStoreListing(appStoreId: '123');
    verify(
      () => review.openStoreListing(
        appStoreId: '123',
        microsoftStoreId: null,
      ),
    ).called(1);
  });

  test('openStoreListing throws when platform fails', () async {
    when(
      () => review.openStoreListing(
        appStoreId: any(named: 'appStoreId'),
        microsoftStoreId: any(named: 'microsoftStoreId'),
      ),
    ).thenThrow(Exception('store'));
    expect(
      () => dataSource.openStoreListing(appStoreId: '123'),
      throwsA(isA<AppReviewFailure>()),
    );
  });
}
