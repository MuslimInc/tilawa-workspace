import 'package:in_app_review/in_app_review.dart';
import 'package:injectable/injectable.dart';

/// Dependency wiring for app review.
///
/// **Current provider:** [InAppReviewPlatformDataSource] (`in_app_review`),
/// registered via `@LazySingleton(as: AppReviewPlatformDataSource)`.
///
/// **Switching to `app_review`:**
/// 1. Add `app_review` to `apps/tilawa/pubspec.yaml`.
/// 2. Create `AppReviewPackagePlatformDataSource` implementing
///    [AppReviewPlatformDataSource] (map `isRequestReviewAvailable` →
///    `isAvailable`, `requestReview` → `requestReview`, `storeListing` →
///    `openStoreListing`).
/// 3. Move `@LazySingleton(as: AppReviewPlatformDataSource)` to that class.
/// 4. Run `dart run build_runner build` and verify on a physical device.
@module
abstract class AppReviewModule {
  @singleton
  InAppReview provideInAppReview() => InAppReview.instance;
}
