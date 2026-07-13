import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/home/presentation/widgets/learn_quran_student_visibility.dart';

void main() {
  tearDown(() async {
    if (getIt.isRegistered<AppLaunchConfig>()) {
      await getIt.unregister<AppLaunchConfig>();
    }
    if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
      await getIt.unregister<QuranSessionsPlatformConfigStore>();
    }
  });

  group('LearnQuranStudentVisibility', () {
    test('shows home card for student when feature enabled', () {
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: true,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
            teacherApplicationEnabled: false,
            teacherApplicationEntryEnabled: false,
            homeTeacherApplicationCardEnabled: false,
            teacherApplicationDiscoverability: 'none',
          ),
        ),
      );

      final show = LearnQuranStudentVisibility.shouldShowHomeCard(
        capabilityLoaded: true,
        capability: const TeacherCapability(state: TeacherCapabilityState.none),
      );
      check(show).isTrue();
    });

    test('hides home card for approved teacher', () {
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: true,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
            teacherApplicationEnabled: false,
            teacherApplicationEntryEnabled: false,
            homeTeacherApplicationCardEnabled: false,
            teacherApplicationDiscoverability: 'none',
          ),
        ),
      );

      final show = LearnQuranStudentVisibility.shouldShowHomeCard(
        capabilityLoaded: true,
        capability: const TeacherCapability(
          state: TeacherCapabilityState.approvedActive,
        ),
      );
      check(show).isFalse();
    });

    test('hides home card while capability unresolved', () {
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: true,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
            teacherApplicationEnabled: false,
            teacherApplicationEntryEnabled: false,
            homeTeacherApplicationCardEnabled: false,
            teacherApplicationDiscoverability: 'none',
          ),
        ),
      );

      final show = LearnQuranStudentVisibility.shouldShowHomeCard(
        capabilityLoaded: false,
        capability: null,
      );
      check(show).isFalse();
    });
  });
}
