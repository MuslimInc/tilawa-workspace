import 'package:get_it/get_it.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';

/// Dependency wiring for app review.
///
/// **Current provider:** [InAppReviewPlatformDataSource] (`in_app_review`).
///
/// **Switching to `app_review`:**
/// 1. Add `app_review` to `apps/tilawa/pubspec.yaml`.
/// 2. Create `AppReviewPackagePlatformDataSource` implementing
///    `AppReviewPlatformDataSource`.
/// 3. Register that class as `AppReviewPlatformDataSource` in [AppReviewDi].
class AppReviewModule {
  AppReviewModule._();

  static void register(GetIt getIt) {
    getIt.registerEagerSingletonIfAbsent<InAppReview>(
      () => InAppReview.instance,
    );
  }
}
