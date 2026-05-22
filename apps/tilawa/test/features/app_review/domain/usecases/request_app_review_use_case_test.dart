import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_repository.dart';
import 'package:tilawa/features/app_review/domain/usecases/request_app_review_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class _FakeRepository implements AppReviewRepository {
  bool unavailable = false;
  bool throwGeneric = false;

  @override
  Future<bool> isAvailable() async => !unavailable;

  @override
  Future<void> requestReview() async {
    if (unavailable) {
      throw const AppReviewFailure.unavailable();
    }
    if (throwGeneric) {
      throw Exception('boom');
    }
  }

  @override
  Future<void> openStoreListing() async {}
}

void main() {
  late _FakeRepository repository;
  late RequestAppReviewUseCase useCase;

  setUp(() {
    repository = _FakeRepository();
    useCase = RequestAppReviewUseCase(repository);
  });

  test('returns Right when review succeeds', () async {
    final result = await useCase();
    result.fold(
      (_) => fail('expected Right'),
      (_) => expect(true, isTrue),
    );
  });

  test('returns AppReviewFailure when unavailable', () async {
    repository.unavailable = true;
    final result = await useCase();
    result.fold(
      (f) => expect(f, isA<AppReviewFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('maps unexpected errors to requestFailed', () async {
    repository.throwGeneric = true;
    final result = await useCase();
    result.fold(
      (f) {
        expect(f, isA<AppReviewFailure>());
        expect(
          (f as AppReviewFailure).reason,
          AppReviewFailureReason.requestFailed,
        );
      },
      (_) => fail('expected Left'),
    );
  });
}
