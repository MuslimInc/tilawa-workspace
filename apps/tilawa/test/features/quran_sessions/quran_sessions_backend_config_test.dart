import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_sessions/di/quran_sessions_backend_config.dart';

void main() {
  test('staging distribution never resolves fake backend', () {
    expect(
      quranSessionsBackendModeFromEnvironment(
        firebaseInitEnabled: true,
        distribution: 'staging',
      ),
      QuranSessionsBackendMode.firebase,
    );
  });

  test('play_production distribution never resolves fake backend', () {
    expect(
      quranSessionsBackendModeFromEnvironment(
        firebaseInitEnabled: true,
        distribution: 'play_production',
      ),
      QuranSessionsBackendMode.firebase,
    );
  });
}
