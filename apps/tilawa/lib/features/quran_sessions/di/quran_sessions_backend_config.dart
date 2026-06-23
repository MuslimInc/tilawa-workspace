/// Backend mode for Quran Sessions dependency injection.
enum QuranSessionsBackendMode {
  /// In-memory fake repositories for local UI development.
  fake,

  /// Firestore + Firebase Auth implementations.
  firebase,
}

/// Resolved from `--dart-define=TILAWA_QURAN_SESSIONS_BACKEND=fake|firebase`.
/// Defaults to [firebase] when Firebase init is enabled.
QuranSessionsBackendMode quranSessionsBackendModeFromEnvironment({
  required bool firebaseInitEnabled,
}) {
  const raw = String.fromEnvironment(
    'TILAWA_QURAN_SESSIONS_BACKEND',
    defaultValue: '',
  );
  return switch (raw) {
    'fake' => QuranSessionsBackendMode.fake,
    'firebase' => QuranSessionsBackendMode.firebase,
    _ =>
      firebaseInitEnabled
          ? QuranSessionsBackendMode.firebase
          : QuranSessionsBackendMode.fake,
  };
}
