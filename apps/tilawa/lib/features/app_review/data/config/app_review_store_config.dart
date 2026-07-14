import 'package:injectable/injectable.dart';

/// Store identifiers for [openStoreListing].
///
/// - Android: always opens the production Play package (flavor suffixes ignored).
/// - iOS: requires App Store ID via `--dart-define=TILAWA_APP_STORE_ID=…`.
@lazySingleton
class AppReviewStoreConfig {
  const AppReviewStoreConfig({
    @ignoreParam
    this.appStoreId = const String.fromEnvironment('TILAWA_APP_STORE_ID'),
    @ignoreParam
    this.microsoftStoreId = const String.fromEnvironment(
      'TILAWA_MICROSOFT_STORE_ID',
    ),
    @ignoreParam
    this.androidPackageId = const String.fromEnvironment(
      'TILAWA_ANDROID_PACKAGE_ID',
      defaultValue: kProductionAndroidPackageId,
    ),
  });

  /// Play Store production package — must match the published listing.
  static const String kProductionAndroidPackageId = 'com.tilawa.app';

  final String appStoreId;
  final String microsoftStoreId;
  final String androidPackageId;

  String? get appStoreIdOrNull => appStoreId.isEmpty ? null : appStoreId;

  String? get microsoftStoreIdOrNull =>
      microsoftStoreId.isEmpty ? null : microsoftStoreId;

  /// Canonical production Play listing for rate / forced-update redirects.
  Uri get playStoreListingUri => playStoreListingUriFor(androidPackageId);

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
