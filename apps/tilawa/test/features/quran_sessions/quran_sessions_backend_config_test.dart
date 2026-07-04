import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_environment.dart';
import 'package:tilawa/features/quran_sessions/di/quran_sessions_backend_config.dart';

void main() {
  test('staging distribution never resolves fake backend', () {
    expect(
      quranSessionsBackendModeFromEnvironment(
        firebaseInitEnabled: true,
        environment: AppEnvironment.staging,
        distribution: 'staging',
      ),
      QuranSessionsBackendMode.firebase,
    );
  });

  test('play_production distribution never resolves fake backend', () {
    expect(
      quranSessionsBackendModeFromEnvironment(
        firebaseInitEnabled: true,
        environment: AppEnvironment.production,
        distribution: 'play_production',
      ),
      QuranSessionsBackendMode.firebase,
    );
  });

  test(
    'production flavor never resolves fake backend even with fake define',
    () {
      expect(
        quranSessionsBackendModeFromEnvironment(
          firebaseInitEnabled: true,
          environment: AppEnvironment.production,
          distribution: 'play_production',
        ),
        QuranSessionsBackendMode.firebase,
      );
    },
  );
}
