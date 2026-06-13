import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_repository.dart';
import 'package:tilawa/features/app_review/domain/usecases/is_app_review_available_use_case.dart';
import 'package:tilawa/features/app_review/domain/usecases/open_app_store_listing_use_case.dart';
import 'package:tilawa/features/app_review/domain/usecases/request_app_review_use_case.dart';
import 'package:tilawa/features/app_review/presentation/cubit/app_review_cubit.dart';
import 'package:tilawa_core/errors/failures.dart';

class _FakeRepo implements AppReviewRepository {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> openStoreListing() async {}

  @override
  Future<void> requestReview() async {}
}

class TestAppReviewCubit extends AppReviewCubit {
  TestAppReviewCubit()
    : super(
        _AlwaysAvailable(),
        _NoOpRequestReview(),
        _NoOpOpenStore(),
      );

  int _rateFromSettingsCalls = 0;

  int get rateFromSettingsCalls => _rateFromSettingsCalls;

  @override
  Future<void> rateFromSettings() async {
    _rateFromSettingsCalls++;
    emit(
      state.copyWith(
        isOpeningStore: true,
        clearFailure: true,
      ),
    );
    emit(state.copyWith(isOpeningStore: false));
  }
}

class _AlwaysAvailable extends IsAppReviewAvailableUseCase {
  _AlwaysAvailable() : super(_FakeRepo());

  @override
  Future<Either<Failure, bool>> call() async => const Right(true);
}

class _NoOpRequestReview extends RequestAppReviewUseCase {
  _NoOpRequestReview() : super(_FakeRepo());

  @override
  Future<Either<Failure, void>> call() async => const Right(null);
}

class _NoOpOpenStore extends OpenAppStoreListingUseCase {
  _NoOpOpenStore() : super(_FakeRepo());

  @override
  Future<Either<Failure, void>> call() async => const Right(null);
}
