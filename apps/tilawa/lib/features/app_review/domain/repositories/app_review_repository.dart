/// Domain contract for in-app review and store-listing flows.
///
/// Presentation and use cases depend on this type only — never on a pub.dev
/// review package.
abstract class AppReviewRepository {
  /// Whether the OS can show an in-app review dialog on this device.
  Future<bool> isAvailable();

  /// Requests the native in-app review UI when [isAvailable] is true.
  Future<void> requestReview();

  /// Opens the platform store listing (fallback when review UI is unavailable).
  ///
  /// When [writeReview] is true on iOS, opens the App Store write-review page.
  Future<void> openStoreListing({bool writeReview = false});
}
