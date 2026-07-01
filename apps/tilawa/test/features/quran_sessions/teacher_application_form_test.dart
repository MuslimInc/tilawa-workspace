import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/utils/legal_url_launcher.dart';
import 'package:tilawa/features/quran_sessions/presentation/teacher_application_entry.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../support/recording_analytics_service.dart';
import '../../support/screen_scope_test_support.dart';

void main() {
  tearDown(() async {
    openLegalUrlOverride = null;
    if (getIt.isRegistered<AppLaunchConfig>()) {
      await getIt.unregister<AppLaunchConfig>();
    }
    if (getIt.isRegistered<AnalyticsService>()) {
      await getIt.unregister<AnalyticsService>();
    }
  });

  testWidgets('openTeacherApplicationForm logs opened on successful launch', (
    tester,
  ) async {
    Uri? launchedUri;
    openLegalUrlOverride = (uri) async {
      launchedUri = uri;
      return true;
    };

    final analytics = RecordingAnalyticsService();
    await resetScopeGetIt();
    getIt
      ..registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          teacherApplicationEntryEnabled: true,
          teacherApplicationFormUrl: kDefaultTeacherApplicationFormUrl,
        ),
      )
      ..registerSingleton<AnalyticsService>(analytics);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => TilawaFeedbackHost(child: child!),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openTeacherApplicationForm(context),
            child: const Text('launch'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    expect(launchedUri?.toString(), kDefaultTeacherApplicationFormUrl);
    expect(
      analytics.events,
      contains(AnalyticsEvents.teacherApplicationFormOpened),
    );
  });

  testWidgets('openTeacherApplicationForm logs failed when launch fails', (
    tester,
  ) async {
    openLegalUrlOverride = (_) async => false;

    final analytics = RecordingAnalyticsService();
    await resetScopeGetIt();
    getIt
      ..registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          teacherApplicationEntryEnabled: true,
          teacherApplicationFormUrl: kDefaultTeacherApplicationFormUrl,
        ),
      )
      ..registerSingleton<AnalyticsService>(analytics);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => TilawaFeedbackHost(child: child!),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openTeacherApplicationForm(context),
            child: const Text('launch'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    expect(
      analytics.events,
      contains(AnalyticsEvents.teacherApplicationFormFailed),
    );
  });
}
