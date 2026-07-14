/// Platform port for in-app review providers.
///
/// **Why this exists:** `in_app_review` and `app_review` expose similar APIs but
/// different packages. Bind a single implementation in
/// `di/app_review_module.dart`
/// so domain/presentation stay unchanged when switching providers.
///
/// **To switch to `app_review` later:**
/// 1. Add `app_review` to `pubspec.yaml`.
/// 2. Implement this interface in a new data-source class (see
///    `in_app_review_platform_data_source.dart` for the reference mapping).
/// 3. Change the `@LazySingleton(as: AppReviewPlatformDataSource)` binding.
abstract class AppReviewPlatformDataSource {
  Future<bool> isAvailable();

  Future<void> requestReview();

  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
    String? androidPackageId,
  });
}
