import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/usecases/is_app_review_available_use_case.dart';
import '../../domain/usecases/open_app_store_listing_use_case.dart';
import '../../domain/usecases/request_app_review_use_case.dart';
import 'app_review_state.dart';

/// Thin presentation API over app-review use cases.
///
/// UI or other blocs can inject this cubit, call [checkAvailability], then
/// [requestReview] or [openStoreListing] without importing platform packages.
@injectable
class AppReviewCubit extends Cubit<AppReviewState> {
  AppReviewCubit(
    this._isAvailable,
    this._requestReview,
    this._openStoreListing,
  ) : super(const AppReviewState());

  final IsAppReviewAvailableUseCase _isAvailable;
  final RequestAppReviewUseCase _requestReview;
  final OpenAppStoreListingUseCase _openStoreListing;

  Future<void> checkAvailability() async {
    emit(
      state.copyWith(
        isCheckingAvailability: true,
        clearFailure: true,
      ),
    );
    final result = await _isAvailable();
    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          isCheckingAvailability: false,
          failure: failure,
        ),
      ),
      (bool available) => emit(
        state.copyWith(
          isCheckingAvailability: false,
          isAvailable: available,
        ),
      ),
    );
  }

  /// Shows the native review dialog when available; otherwise opens the store.
  Future<void> requestReview({bool openStoreOnUnavailable = true}) async {
    emit(
      state.copyWith(
        isRequestingReview: true,
        clearFailure: true,
      ),
    );
    final result = await _requestReview();
    await result.fold(
      (Failure failure) async {
        if (openStoreOnUnavailable &&
            failure is AppReviewFailure &&
            failure.reason == AppReviewFailureReason.unavailable) {
          await openStoreListing();
          return;
        }
        emit(
          state.copyWith(
            isRequestingReview: false,
            failure: failure,
          ),
        );
      },
      (_) async {
        emit(state.copyWith(isRequestingReview: false));
      },
    );
  }

  Future<void> openStoreListing() async {
    emit(
      state.copyWith(
        isOpeningStore: true,
        clearFailure: true,
      ),
    );
    final result = await _openStoreListing();
    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          isOpeningStore: false,
          isRequestingReview: false,
          failure: failure,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isOpeningStore: false,
          isRequestingReview: false,
        ),
      ),
    );
  }
}
