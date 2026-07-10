import '../../../core/bootstrap/app_environment.dart';

/// Backend mode for Quran Sessions dependency injection.
enum QuranSessionsBackendMode {
  /// In-memory fake repositories for local UI development.
  fake,

  /// Firestore + Firebase Auth implementations.
  firebase,
}

/// Resolved from explicit dart-defines only (Q-BE-02).
///
/// Fake backend requires one of:
/// - `--dart-define=TILAWA_QURAN_SESSIONS_BACKEND=fake`
/// - `--dart-define=USE_QURAN_SESSIONS_MVP_FAKE=true`
///
/// Defaults to [firebase] — never silently falls back to fake.
/// Fake is **never** allowed in staging or production flavors, even if
/// dart-defines request it.
QuranSessionsBackendMode quranSessionsBackendModeFromEnvironment({
  required bool firebaseInitEnabled,
  AppEnvironment? environment,
  String? distribution,
}) {
  final env = environment ?? AppEnvironment.current;
  final dist = distribution ?? resolvedTilawaDistribution(environment: env);
  if (!env.allowsFakeQuranSessionsBackend ||
      dist == 'staging' ||
      dist == 'play_production') {
    return QuranSessionsBackendMode.firebase;
  }

  const raw = String.fromEnvironment(
    'TILAWA_QURAN_SESSIONS_BACKEND',
    defaultValue: '',
  );
  const fakeOptIn = String.fromEnvironment(
    'USE_QURAN_SESSIONS_MVP_FAKE',
    defaultValue: '',
  );
  return switch (raw) {
    'fake' => QuranSessionsBackendMode.fake,
    'firebase' => QuranSessionsBackendMode.firebase,
    _ =>
      fakeOptIn == 'true'
          ? QuranSessionsBackendMode.fake
          : QuranSessionsBackendMode.firebase,
  };
}
