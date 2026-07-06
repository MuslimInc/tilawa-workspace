/// Compile-time app flavor / environment.
///
/// Prefer `--dart-define=APP_ENV=development|staging|production` (or
/// `--dart-define-from-file=env/<flavor>.json`). When [APP_ENV] is absent,
/// [current] falls back to [fromDistribution] using [TILAWA_DISTRIBUTION].
enum AppEnvironment {
  /// Local engineering builds (`TILAWA_DISTRIBUTION=local` by default).
  development,

  /// Staging Firebase + QA overrides (`TILAWA_DISTRIBUTION=staging`).
  staging,

  /// Store / production builds (`TILAWA_DISTRIBUTION=play_production`).
  production;

  static const String appEnvKey = 'APP_ENV';

  static const String distributionKey = 'TILAWA_DISTRIBUTION';

  static const String _rawAppEnv = String.fromEnvironment(
    appEnvKey,
    defaultValue: '',
  );

  static const String _explicitDistribution = String.fromEnvironment(
    distributionKey,
    defaultValue: '',
  );

  static const String _fallbackDistribution = String.fromEnvironment(
    distributionKey,
    defaultValue: 'local',
  );

  /// Resolved compile-time environment.
  static AppEnvironment get current => fromRaw(
    _rawAppEnv,
    distribution: _fallbackDistribution,
  );

  /// Parses [rawAppEnv] when non-empty; otherwise maps [distribution].
  static AppEnvironment fromRaw(
    String rawAppEnv, {
    required String distribution,
  }) {
    final normalized = rawAppEnv.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      return switch (normalized) {
        'development' || 'dev' => AppEnvironment.development,
        'staging' => AppEnvironment.staging,
        'production' || 'prod' => AppEnvironment.production,
        _ => throw StateError('Unknown $appEnvKey: $rawAppEnv'),
      };
    }
    return fromDistribution(distribution);
  }

  /// Maps legacy [TILAWA_DISTRIBUTION] values to an [AppEnvironment].
  static AppEnvironment fromDistribution(String distribution) {
    final normalized = distribution.trim();
    if (normalized == 'play_production' || normalized == 'production') {
      return AppEnvironment.production;
    }
    if (normalized == 'staging') {
      return AppEnvironment.staging;
    }
    return AppEnvironment.development;
  }

  /// Default distribution when `TILAWA_DISTRIBUTION` is not set explicitly.
  String get defaultDistribution => switch (this) {
    AppEnvironment.production => 'play_production',
    AppEnvironment.staging => 'staging',
    AppEnvironment.development => 'local',
  };

  /// Sentry `environment` tag for this build.
  String get sentryEnvironment => name;

  /// Staging QA join-window bypass is never allowed in production.
  bool get allowsQaJoinWindowBypass => this != AppEnvironment.production;

  /// In-memory fake Quran Sessions backend is dev-only.
  bool get allowsFakeQuranSessionsBackend => this == AppEnvironment.development;

  /// Fail fast when production build enables unsafe compile-time overrides.
  static void assertProductionSafety({
    AppEnvironment? environment,
    String? distribution,
    String quranSessionsBackend = const String.fromEnvironment(
      'TILAWA_QURAN_SESSIONS_BACKEND',
      defaultValue: '',
    ),
    String useQuranSessionsMvpFake = const String.fromEnvironment(
      'USE_QURAN_SESSIONS_MVP_FAKE',
      defaultValue: '',
    ),
  }) {
    final env = environment ?? current;
    final dist = distribution ?? resolvedDistribution;
    if (env != AppEnvironment.production) {
      return;
    }

    if (quranSessionsBackend == 'fake' || useQuranSessionsMvpFake == 'true') {
      throw StateError(
        'Fake Quran Sessions backend is not allowed in production '
        '(APP_ENV=$env, TILAWA_DISTRIBUTION=$dist).',
      );
    }

    if (dist == 'staging' || dist == 'local') {
      throw StateError(
        'Production flavor cannot use TILAWA_DISTRIBUTION=$dist. '
        'Use play_production or a play_<track> value.',
      );
    }
  }
}

/// Effective distribution string for telemetry and feature flags.
///
/// Explicit `--dart-define=TILAWA_DISTRIBUTION=…` wins over [AppEnvironment]
/// defaults so CI Play tracks (`play_internal`, `play_alpha`, …) keep working.
String get resolvedDistribution {
  final explicit = AppEnvironment._explicitDistribution.trim();
  if (explicit.isNotEmpty) {
    return explicit;
  }
  return AppEnvironment.current.defaultDistribution;
}

/// Effective distribution for const launch-flag defaults.
String resolvedTilawaDistribution({
  AppEnvironment? environment,
  String? explicitDistribution,
}) {
  final explicit =
      (explicitDistribution ?? AppEnvironment._explicitDistribution).trim();
  if (explicit.isNotEmpty) {
    return explicit;
  }
  return (environment ?? AppEnvironment.current).defaultDistribution;
}
