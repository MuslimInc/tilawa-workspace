import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/home/presentation/widgets/home_featured_tutor_card.dart';
import 'package:tilawa/features/quran_sessions/presentation/teacher_application_entry.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/recording_analytics_service.dart';
import '../../../../support/screen_scope_test_support.dart';

Future<void> _pumpHomeCard(
  WidgetTester tester, {
  required AppLaunchConfig config,
  Locale locale = const Locale('ar'),
}) async {
  await resetScopeGetIt();
  getIt.registerSingleton<AppLaunchConfig>(config);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: HomeFeaturedTutorCard()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async {
    if (getIt.isRegistered<AppLaunchConfig>()) {
      await getIt.unregister<AppLaunchConfig>();
    }
  });

  testWidgets('hides student learn card when student feature disabled', (
    tester,
  ) async {
    await _pumpHomeCard(
      tester,
      config: const AppLaunchConfig(
        quranSessionsEnabled: true,
        learnQuranStudentFeatureEnabled: false,
      ),
    );

    expect(find.text('Learn Quran'), findsNothing);
    expect(find.text('تعلّم القرآن مع محفظك'), findsNothing);
  });

  testWidgets('shows teacher application card only when explicitly enabled', (
    tester,
  ) async {
    await _pumpHomeCard(
      tester,
      config: const AppLaunchConfig(
        teacherApplicationEntryEnabled: true,
        homeTeacherApplicationCardEnabled: true,
      ),
    );

    expect(find.text('التقديم كمعلّم قرآن'), findsOneWidget);
    expect(find.text('فتح نموذج التقديم'), findsOneWidget);
  });

  testWidgets('teacher application card tap opens sheet not auto on pump', (
    tester,
  ) async {
    await _pumpHomeCard(
      tester,
      config: const AppLaunchConfig(
        teacherApplicationEntryEnabled: true,
        homeTeacherApplicationCardEnabled: true,
      ),
    );

    expect(find.text('هل أنت محفّظ أو معلّم قرآن؟'), findsNothing);

    await tester.tap(find.byType(TilawaInteractiveSurface));
    await tester.pumpAndSettle();

    expect(find.text('هل أنت محفّظ أو معلّم قرآن؟'), findsOneWidget);
  });

  testWidgets('sheet primary CTA logs analytics and closes sheet', (
    tester,
  ) async {
    final analytics = RecordingAnalyticsService();
    await resetScopeGetIt();
    getIt
      ..registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(teacherApplicationEntryEnabled: true),
      )
      ..registerSingleton<AnalyticsService>(analytics);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showTeacherApplicationEntrySheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      analytics.events,
      contains(AnalyticsEvents.teacherApplicationEntrySeen),
    );

    await tester.tap(find.text('فتح نموذج التقديم'));
    await tester.pumpAndSettle();

    expect(
      analytics.events,
      contains(AnalyticsEvents.teacherApplicationEntryTapped),
    );
    expect(find.text('هل أنت محفّظ أو معلّم قرآن؟'), findsNothing);
  });
}
