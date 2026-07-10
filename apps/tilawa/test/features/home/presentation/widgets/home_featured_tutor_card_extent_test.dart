import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/home/presentation/widgets/home_featured_tutor_card.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('extentFor covers rendered card height', (tester) async {
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(),
    );
    // Feature flags fail closed without the runtime platform-config store —
    // register an enabled config so the featured tutor card renders.
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
    addTearDown(() async {
      if (getIt.isRegistered<AppLaunchConfig>()) {
        await getIt.unregister<AppLaunchConfig>();
      }
      if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
        await getIt.unregister<QuranSessionsPlatformConfigStore>();
      }
    });

    for (final Size size in <Size>[
      const Size(360, 640),
      const Size(320, 568),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HomeFeaturedTutorCard()),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(HomeFeaturedTutorCard),
      );
      final double extent = HomeFeaturedTutorCardLayout.extentFor(context);
      final double cardHeight = tester
          .getSize(find.byType(TilawaInteractiveSurface))
          .height;
      final double available = extent - context.tokens.spaceMedium;

      expect(
        available,
        greaterThanOrEqualTo(cardHeight - 1),
        reason: 'size=$size extent=$extent card=$cardHeight',
      );
    }
  });
}
