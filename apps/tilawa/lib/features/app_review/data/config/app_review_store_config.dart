/// Store identifiers and listing URLs for rate / share / forced-update.
///
/// - Android: always the production Play package (flavor suffixes ignored).
/// - iOS: App Store ID via `--dart-define=TILAWA_APP_STORE_ID=…`, defaulting
///   to [kProductionAppStoreId].
class AppReviewStoreConfig {
  const AppReviewStoreConfig({
    this.appStoreId = const String.fromEnvironment(
      'TILAWA_APP_STORE_ID',
      defaultValue: kProductionAppStoreId,
    ),
    this.microsoftStoreId = const String.fromEnvironment(
      'TILAWA_MICROSOFT_STORE_ID',
    ),
    this.androidPackageId = const String.fromEnvironment(
      'TILAWA_ANDROID_PACKAGE_ID',
      defaultValue: kProductionAndroidPackageId,
    ),
  });

  /// App Store numeric ID — country-agnostic listing (`/app/id…`).
  static const String kProductionAppStoreId = '6791827426';

  /// Play Store production package — must match the published listing.
  static const String kProductionAndroidPackageId = 'com.tilawa.app';

  final String appStoreId;
  final String microsoftStoreId;
  final String androidPackageId;

  String? get appStoreIdOrNull => appStoreId.isEmpty ? null : appStoreId;

  String? get microsoftStoreIdOrNull =>
      microsoftStoreId.isEmpty ? null : microsoftStoreId;

  /// Canonical production App Store listing (no country segment).
  Uri get appStoreListingUri => appStoreListingUriFor(appStoreId);

  /// App Store write-review deep link for explicit “Rate MeMuslim” actions.
  Uri get appStoreWriteReviewUri => appStoreWriteReviewUriFor(appStoreId);

  /// Canonical production Play listing for rate / forced-update redirects.
  Uri get playStoreListingUri => playStoreListingUriFor(androidPackageId);

  /// Builds the App Store URI, falling back to [kProductionAppStoreId].
  static Uri appStoreListingUriFor(String? appStoreId) {
    final String resolved = (appStoreId == null || appStoreId.isEmpty)
        ? kProductionAppStoreId
        : appStoreId.trim();
    return Uri.https('apps.apple.com', '/app/id$resolved');
  }

  /// Builds the App Store write-review URI used by settings rating.
  static Uri appStoreWriteReviewUriFor(String? appStoreId) {
    return appStoreListingUriFor(appStoreId).replace(
      queryParameters: const <String, String>{'action': 'write-review'},
    );
  }

  /// Builds the Play details URI, falling back to [kProductionAndroidPackageId].
  static Uri playStoreListingUriFor(String? packageId) {
    final String resolved = (packageId == null || packageId.isEmpty)
        ? kProductionAndroidPackageId
        : packageId;
    return Uri.https(
      'play.google.com',
      '/store/apps/details',
      <String, String>{'id': resolved},
    );
  }
}
