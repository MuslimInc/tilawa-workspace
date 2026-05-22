import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_repository.dart';
import 'package:tilawa/features/app_review/domain/usecases/is_app_review_available_use_case.dart';
import 'package:tilawa/features/app_review/domain/usecases/open_app_store_listing_use_case.dart';
import 'package:tilawa/features/app_review/domain/usecases/request_app_review_use_case.dart';
import 'package:tilawa/features/app_review/presentation/cubit/app_review_cubit.dart';
import 'package:tilawa/features/app_review/presentation/cubit/app_review_state.dart';
import 'package:tilawa_core/errors/failures.dart';

class _FakeRepo implements AppReviewRepository {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> openStoreListing() async {}

  @override
  Future<void> requestReview() async {}
}

class _StubIsAvailable extends IsAppReviewAvailableUseCase {
  _StubIsAvailable(this._result) : super(_FakeRepo());

  final Either<Failure, bool> _result;

  @override
  Future<Either<Failure, bool>> call() async => _result;
}

class _StubRequestReview extends RequestAppReviewUseCase {
  _StubRequestReview(this._result) : super(_FakeRepo());

  final Either<Failure, void> _result;

  @override
  Future<Either<Failure, void>> call() async => _result;
}

class _StubOpenStore extends OpenAppStoreListingUseCase {
  _StubOpenStore(this._result) : super(_FakeRepo());

  final Either<Failure, void> _result;

  @override
  Future<Either<Failure, void>> call() async => _result;
}

void main() {
  blocTest<AppReviewCubit, AppReviewState>(
    'checkAvailability emits availability',
    build: () => AppReviewCubit(
      _StubIsAvailable(const Right(true)),
      _StubRequestReview(const Right(null)),
      _StubOpenStore(const Right(null)),
    ),
    act: (AppReviewCubit cubit) => cubit.checkAvailability(),
    expect: () => <Matcher>[
      isA<AppReviewState>().having(
        (AppReviewState s) => s.isCheckingAvailability,
        'isCheckingAvailability',
        true,
      ),
      isA<AppReviewState>().having(
        (AppReviewState s) => s.isAvailable,
        'isAvailable',
        true,
      ),
    ],
  );

  blocTest<AppReviewCubit, AppReviewState>(
    'requestReview emits failure when unavailable without store fallback',
    build: () => AppReviewCubit(
      _StubIsAvailable(const Right(true)),
      _StubRequestReview(const Left(AppReviewFailure.requestFailed())),
      _StubOpenStore(const Right(null)),
    ),
    act: (AppReviewCubit cubit) =>
        cubit.requestReview(openStoreOnUnavailable: false),
    expect: () => <Matcher>[
      isA<AppReviewState>().having(
        (AppReviewState s) => s.isRequestingReview,
        'isRequestingReview',
        true,
      ),
      isA<AppReviewState>().having(
        (AppReviewState s) => s.failure,
        'failure',
        isA<AppReviewFailure>(),
      ),
    ],
  );

  blocTest<AppReviewCubit, AppReviewState>(
    'requestReview opens store when unavailable and fallback enabled',
    build: () => AppReviewCubit(
      _StubIsAvailable(const Right(true)),
      _StubRequestReview(const Left(AppReviewFailure.unavailable())),
      _StubOpenStore(const Right(null)),
    ),
    act: (AppReviewCubit cubit) => cubit.requestReview(),
    expect: () => <Matcher>[
      isA<AppReviewState>(),
      isA<AppReviewState>().having(
        (AppReviewState s) => s.isOpeningStore,
        'isOpeningStore',
        true,
      ),
      isA<AppReviewState>().having(
        (AppReviewState s) => s.isOpeningStore,
        'isOpeningStore',
        false,
      ),
    ],
  );

  blocTest<AppReviewCubit, AppReviewState>(
    'checkAvailability emits failure',
    build: () => AppReviewCubit(
      _StubIsAvailable(const Left(AppReviewFailure.requestFailed())),
      _StubRequestReview(const Right(null)),
      _StubOpenStore(const Right(null)),
    ),
    act: (AppReviewCubit cubit) => cubit.checkAvailability(),
    expect: () => <Matcher>[
      isA<AppReviewState>(),
      isA<AppReviewState>().having(
        (AppReviewState s) => s.failure,
        'failure',
        isA<AppReviewFailure>(),
      ),
    ],
  );

  blocTest<AppReviewCubit, AppReviewState>(
    'requestReview clears busy flag on success',
    build: () => AppReviewCubit(
      _StubIsAvailable(const Right(true)),
      _StubRequestReview(const Right(null)),
      _StubOpenStore(const Right(null)),
    ),
    act: (AppReviewCubit cubit) =>
        cubit.requestReview(openStoreOnUnavailable: false),
    expect: () => <Matcher>[
      isA<AppReviewState>().having(
        (AppReviewState s) => s.isRequestingReview,
        'isRequestingReview',
        true,
      ),
      isA<AppReviewState>().having(
        (AppReviewState s) => s.isRequestingReview,
        'isRequestingReview',
        false,
      ),
    ],
  );

  blocTest<AppReviewCubit, AppReviewState>(
    'openStoreListing emits failure on error',
    build: () => AppReviewCubit(
      _StubIsAvailable(const Right(true)),
      _StubRequestReview(const Right(null)),
      _StubOpenStore(const Left(AppReviewFailure.storeListingFailed())),
    ),
    act: (AppReviewCubit cubit) => cubit.openStoreListing(),
    expect: () => <Matcher>[
      isA<AppReviewState>(),
      isA<AppReviewState>().having(
        (AppReviewState s) => s.failure,
        'failure',
        isA<AppReviewFailure>(),
      ),
    ],
  );
}
