import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_repository.dart';
import 'package:tilawa/features/app_review/domain/usecases/open_app_store_listing_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class _FakeRepository implements AppReviewRepository {
  bool throwFailure = false;
  bool throwGeneric = false;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> openStoreListing() async {
    if (throwFailure) {
      throw const AppReviewFailure.storeListingFailed('store');
    }
    if (throwGeneric) {
      throw Exception('boom');
    }
  }

  @override
  Future<void> requestReview() async {}
}

void main() {
  late _FakeRepository repository;
  late OpenAppStoreListingUseCase useCase;

  setUp(() {
    repository = _FakeRepository();
    useCase = OpenAppStoreListingUseCase(repository);
  });

  test('returns Right when store opens', () async {
    final result = await useCase();
    result.fold(
      (_) => fail('expected Right'),
      (_) => expect(true, isTrue),
    );
  });

  test('returns AppReviewFailure when repository throws it', () async {
    repository.throwFailure = true;
    final result = await useCase();
    result.fold(
      (Failure failure) => expect(failure, isA<AppReviewFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('maps unexpected errors to storeListingFailed', () async {
    repository.throwGeneric = true;
    final result = await useCase();
    result.fold(
      (Failure failure) {
        expect(failure, isA<AppReviewFailure>());
        expect(
          (failure as AppReviewFailure).reason,
          AppReviewFailureReason.storeListingFailed,
        );
      },
      (_) => fail('expected Left'),
    );
  });
}
