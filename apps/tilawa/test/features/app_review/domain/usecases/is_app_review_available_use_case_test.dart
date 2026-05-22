import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_repository.dart';
import 'package:tilawa/features/app_review/domain/usecases/is_app_review_available_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class _FakeRepository implements AppReviewRepository {
  bool available = true;
  bool throwGeneric = false;
  bool throwAppReviewFailure = false;

  @override
  Future<bool> isAvailable() async {
    if (throwAppReviewFailure) {
      throw const AppReviewFailure.unavailable();
    }
    if (throwGeneric) {
      throw Exception('boom');
    }
    return available;
  }

  @override
  Future<void> openStoreListing() async {}

  @override
  Future<void> requestReview() async {}
}

void main() {
  late _FakeRepository repository;
  late IsAppReviewAvailableUseCase useCase;

  setUp(() {
    repository = _FakeRepository();
    useCase = IsAppReviewAvailableUseCase(repository);
  });

  test('returns Right with availability', () async {
    repository.available = false;
    final result = await useCase();
    result.fold(
      (_) => fail('expected Right'),
      (bool value) => expect(value, isFalse),
    );
  });

  test('returns AppReviewFailure from repository', () async {
    repository.throwAppReviewFailure = true;
    final result = await useCase();
    result.fold(
      (Failure failure) => expect(failure, isA<AppReviewFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('maps unexpected errors to requestFailed', () async {
    repository.throwGeneric = true;
    final result = await useCase();
    result.fold(
      (Failure failure) {
        expect(failure, isA<AppReviewFailure>());
        expect(
          (failure as AppReviewFailure).reason,
          AppReviewFailureReason.requestFailed,
        );
      },
      (_) => fail('expected Left'),
    );
  });
}
