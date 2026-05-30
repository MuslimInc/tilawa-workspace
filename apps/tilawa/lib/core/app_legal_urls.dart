/// Public legal URLs for Play Console and in-app links.
///
/// Override at build time when needed:
/// `--dart-define=TILAWA_PRIVACY_POLICY_URL=https://...`
abstract final class AppLegalUrls {
  AppLegalUrls._();

  static const String privacyPolicy = String.fromEnvironment(
    'TILAWA_PRIVACY_POLICY_URL',
    defaultValue: 'https://tilawa.app/privacy',
  );

  static const String accountDeletion = String.fromEnvironment(
    'TILAWA_ACCOUNT_DELETION_URL',
    defaultValue: 'https://tilawa.app/delete-account',
  );
}
