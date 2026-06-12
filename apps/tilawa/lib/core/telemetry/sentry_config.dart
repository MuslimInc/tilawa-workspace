/// Sentry client configuration for Tilawa.
///
/// Override at build time with `--dart-define=SENTRY_DSN=...` if needed.
abstract final class SentryConfig {
  static const String dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://af9b4898a6280f738a01dd7e407982be@o4510837450211328.ingest.us.sentry.io/4511544533516288',
  );
}
