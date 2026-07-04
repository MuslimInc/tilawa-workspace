import 'package:checks/checks.dart';
import 'package:test/test.dart';

import 'package:tilawa/core/bootstrap/app_environment.dart';

void main() {
  group('AppEnvironment.fromDistribution', () {
    test('maps play_production to production', () {
      check(
        AppEnvironment.fromDistribution('play_production'),
      ).equals(AppEnvironment.production);
    });

    test('maps staging to staging', () {
      check(
        AppEnvironment.fromDistribution('staging'),
      ).equals(AppEnvironment.staging);
    });

    test('maps local and play tracks to development', () {
      check(
        AppEnvironment.fromDistribution('local'),
      ).equals(AppEnvironment.development);
      check(
        AppEnvironment.fromDistribution('play_internal'),
      ).equals(AppEnvironment.development);
    });
  });

  group('resolvedTilawaDistribution', () {
    test('uses explicit distribution when provided', () {
      check(
        resolvedTilawaDistribution(
          environment: AppEnvironment.production,
          explicitDistribution: 'play_beta',
        ),
      ).equals('play_beta');
    });

    test('defaults production flavor to play_production', () {
      check(
        resolvedTilawaDistribution(
          environment: AppEnvironment.production,
          explicitDistribution: '',
        ),
      ).equals('play_production');
    });

    test('defaults staging flavor to staging', () {
      check(
        resolvedTilawaDistribution(
          environment: AppEnvironment.staging,
          explicitDistribution: '',
        ),
      ).equals('staging');
    });
  });

  group('quranSessionsStagingFlagsDefaultEnabled', () {
    test('is off when distribution is play_production', () {
      check(
        quranSessionsStagingFlagsDefaultEnabled(
          distribution: 'play_production',
        ),
      ).equals(false);
    });

    test('is on for staging flavor', () {
      check(
        quranSessionsStagingFlagsDefaultEnabled(
          distribution: 'staging',
        ),
      ).equals(true);
    });

    test('is on for play internal track', () {
      check(
        quranSessionsStagingFlagsDefaultEnabled(
          distribution: 'play_internal',
        ),
      ).equals(true);
    });
  });

  group('AppEnvironment.assertProductionSafety', () {
    test('throws when fake backend requested in production', () {
      check(
        () => AppEnvironment.assertProductionSafety(
          environment: AppEnvironment.production,
          distribution: 'play_production',
          quranSessionsBackend: 'fake',
        ),
      ).throws<StateError>();
    });

    test('throws when production flavor uses staging distribution', () {
      check(
        () => AppEnvironment.assertProductionSafety(
          environment: AppEnvironment.production,
          distribution: 'staging',
        ),
      ).throws<StateError>();
    });

    test('throws when production flavor uses local distribution', () {
      check(
        () => AppEnvironment.assertProductionSafety(
          environment: AppEnvironment.production,
          distribution: 'local',
        ),
      ).throws<StateError>();
    });

    test('allows play internal track on production flavor', () {
      AppEnvironment.assertProductionSafety(
        environment: AppEnvironment.production,
        distribution: 'play_internal',
      );
    });

    test('passes for valid production build', () {
      AppEnvironment.assertProductionSafety(
        environment: AppEnvironment.production,
        distribution: 'play_production',
      );
    });
  });
}
