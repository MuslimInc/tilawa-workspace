import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';

void main() {
  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('missing admin config fails closed', () {
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(),
    );

    final config = quranSessionsFeatureConfig();

    check(config.quranSessionsEnabled).isFalse();
    check(config.showLearnQuranStudentExperience).isFalse();
    check(config.quranSessionsBookingEnabled).isFalse();
    check(config.walletEnabled).isFalse();
  });

  test('admin config enables student entry and booking', () {
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(),
    );
    final store = QuranSessionsPlatformConfigStore()
      ..setConfig(
        const QuranSessionsPlatformConfig(
          quranSessionsEnabled: true,
          studentEntryEnabled: true,
          bookingEnabled: true,
          bookingMode: 'autoConfirm',
          sessionMode: 'videoOnly',
          enabledCallProviders: {'external', 'mock'},
          walletEnabled: true,
        ),
      );
    getIt.registerSingleton<QuranSessionsPlatformConfigStore>(store);

    final config = quranSessionsFeatureConfig();

    check(config.quranSessionsEnabled).isTrue();
    check(config.showLearnQuranStudentExperience).isTrue();
    check(config.quranSessionsBookingEnabled).isTrue();
    check(config.walletEnabled).isTrue();
  });

  test('admin config overrides launch config', () {
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(),
    );
    final store = QuranSessionsPlatformConfigStore()
      ..setConfig(
        const QuranSessionsPlatformConfig(
          quranSessionsEnabled: false,
          studentEntryEnabled: false,
          bookingEnabled: false,
          bookingMode: 'requiresTutorApproval',
          sessionMode: 'videoOnly',
          enabledCallProviders: {'external'},
          walletEnabled: false,
        ),
      );
    getIt.registerSingleton<QuranSessionsPlatformConfigStore>(store);

    final config = quranSessionsFeatureConfig();

    check(config.quranSessionsEnabled).isFalse();
    check(config.showLearnQuranStudentExperience).isFalse();
    check(config.quranSessionsBookingEnabled).isFalse();
    check(config.walletEnabled).isFalse();
  });
}
