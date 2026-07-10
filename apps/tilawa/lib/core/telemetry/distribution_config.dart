import '../bootstrap/app_environment.dart';

/// How this build was distributed.
///
/// CI Play releases set this from the upload track, e.g.
/// `play_internal`, `play_alpha`, `play_beta`, `play_production`.
/// Local dev builds default to `local`.
abstract final class DistributionConfig {
  static const String distribution = String.fromEnvironment(
    AppEnvironment.distributionKey,
    defaultValue: 'local',
  );

  /// Distribution with [AppEnvironment] fallback when explicit define absent.
  static String get resolved => resolvedDistribution;
}
