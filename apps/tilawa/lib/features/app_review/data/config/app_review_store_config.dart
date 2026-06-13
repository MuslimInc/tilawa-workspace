import 'package:injectable/injectable.dart';

/// Optional store identifiers for [openStoreListing].
///
/// iOS requires an App Store ID for review screens. Override via:
/// `--dart-define=TILAWA_APP_STORE_ID=123456789`
@lazySingleton
class AppReviewStoreConfig {
  const AppReviewStoreConfig({
    @ignoreParam
    this.appStoreId = const String.fromEnvironment('TILAWA_APP_STORE_ID'),
    @ignoreParam
    this.microsoftStoreId = const String.fromEnvironment(
      'TILAWA_MICROSOFT_STORE_ID',
    ),
  });

  final String appStoreId;
  final String microsoftStoreId;

  String? get appStoreIdOrNull => appStoreId.isEmpty ? null : appStoreId;

  String? get microsoftStoreIdOrNull =>
      microsoftStoreId.isEmpty ? null : microsoftStoreId;
}
