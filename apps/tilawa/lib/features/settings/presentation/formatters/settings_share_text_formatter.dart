import 'package:flutter/foundation.dart';
import 'package:tilawa/features/app_review/data/config/app_review_store_config.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/constants/app_strings.dart';

/// Builds the localized share text with both App Store and Play Store links.
///
/// Always uses production store IDs — flavor package suffixes (`.dev` /
/// `.staging`) and flavor display names are ignored so shared links open the
/// published listings.
String buildSettingsShareAppText(
  AppLocalizations l10n, {
  String? appStoreId,
  String? androidPackageId,
}) {
  final urls = settingsShareStoreUrls(
    appStoreId: appStoreId,
    androidPackageId: androidPackageId,
  );

  return l10n.shareTilawaMessage(
    AppStrings.appName,
    urls.iosStoreUrl,
    urls.androidStoreUrl,
  );
}

/// Production store listing URLs used in share text.
///
/// Optional overrides exist for tests only; production callers pass nothing.
@visibleForTesting
({String iosStoreUrl, String androidStoreUrl}) settingsShareStoreUrls({
  String? appStoreId,
  String? androidPackageId,
}) {
  return (
    iosStoreUrl: AppReviewStoreConfig.appStoreListingUriFor(
      appStoreId,
    ).toString(),
    androidStoreUrl: AppReviewStoreConfig.playStoreListingUriFor(
      androidPackageId,
    ).toString(),
  );
}
