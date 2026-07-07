import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/home/presentation/widgets/home_featured_tutor_card.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/recording_analytics_service.dart';
import '../../../../support/screen_scope_test_support.dart';

final class _NullAuthSessionProvider implements AuthSessionProvider {
  @override
  String? get currentUserId => null;

  @override
  Stream<String?> watchUserId() => const Stream.empty();
}

int _countSemanticsButtons(WidgetTester tester) {
  var count = 0;
  void walkNode(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isButton) {
      count++;
    }
    node.visitChildren((child) {
      walkNode(child);
      return true;
    });
  }

  void walkOwner(PipelineOwner owner) {
    final root = owner.semanticsOwner?.rootSemanticsNode;
    if (root != null) {
      walkNode(root);
    }
    owner.visitChildren(walkOwner);
  }

  walkOwner(tester.binding.rootPipelineOwner);
  return count;
}

Future<void> _pumpCard(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
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

/// Pumps the card inside a [GoRouter] so taps can navigate without throwing.
/// A null current user routes Learn Quran taps to a stub `/login`.
Future<RecordingAnalyticsService> _pumpRoutedCard(WidgetTester tester) async {
  final analytics = RecordingAnalyticsService();
  getIt
    ..registerSingleton<QuranSessionsPlatformConfigStore>(
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
    )
    ..registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(
        quranSessionsEnabled: true,
        learnQuranStudentFeatureEnabled: true,
      ),
    )
    ..registerSingleton<AnalyticsService>(analytics)
    ..registerSingleton<AuthSessionProvider>(_NullAuthSessionProvider());

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: HomeFeaturedTutorCard()),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
  return analytics;
}

void main() {
  // VisibilityDetector is configured to report synchronously for the whole
  // app test suite in test/flutter_test_config.dart.
  tearDown(() async {
    if (getIt.isRegistered<AppLaunchConfig>()) {
      await getIt.unregister<AppLaunchConfig>();
    }
    if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
      await getIt.unregister<QuranSessionsPlatformConfigStore>();
    }
  });

  testWidgets('hides Learn Quran card for approved teacher', (tester) async {
    await resetScopeGetIt();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(
        quranSessionsEnabled: true,
        learnQuranStudentFeatureEnabled: true,
      ),
    );
    getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
      QuranSessionsPlatformConfigStore()..setConfig(
        QuranSessionsPlatformConfig(
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

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: HomeFeaturedTutorCard(
            capability: TeacherCapability(
              state: TeacherCapabilityState.approvedActive,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learn Quran'), findsNothing);
    expect(find.byType(TilawaInteractiveSurface), findsNothing);
  });

  testWidgets('English home featured card shows Learn Quran not QuranTutor', (
    tester,
  ) async {
    await resetScopeGetIt();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(
        quranSessionsEnabled: true,
        learnQuranStudentFeatureEnabled: true,
      ),
    );
    getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
      QuranSessionsPlatformConfigStore()..setConfig(
        QuranSessionsPlatformConfig(
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

    await _pumpCard(tester);

    expect(find.text('Learn Quran'), findsOneWidget);
    expect(find.text('Experimental'), findsOneWidget);
    expect(find.byType(TilawaExperimentalBadge), findsOneWidget);

    final theme = AppTheme.getLightTheme(
      primaryColor: AppColors.defaultPrimary,
    );
    final badgeText = tester.widget<Text>(find.text('Experimental'));
    expect(badgeText.style?.color, theme.colorScheme.onSurface);

    expect(find.text('Featured'), findsNothing);
    expect(find.text('Start learning'), findsOneWidget);
    expect(find.text('QuranTutor'), findsNothing);
    expect(find.text('Quran Tutor'), findsNothing);
  });

  testWidgets('Arabic home featured card keeps long marketing title', (
    tester,
  ) async {
    await resetScopeGetIt();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(
        quranSessionsEnabled: true,
        learnQuranStudentFeatureEnabled: true,
      ),
    );
    getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
      QuranSessionsPlatformConfigStore()..setConfig(
        QuranSessionsPlatformConfig(
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

    await _pumpCard(tester, locale: const Locale('ar'));

    expect(find.text('تعلّم القرآن مع محفظك'), findsOneWidget);
    expect(find.text('تجريبي'), findsOneWidget);
    expect(find.byType(TilawaExperimentalBadge), findsOneWidget);
    expect(find.text('مميّز'), findsNothing);
    expect(find.text('ابدأ التعلّم'), findsOneWidget);
    expect(find.text('تلاوة'), findsNothing);
  });

  testWidgets(
    'featured tutor sliver lays out without geometry errors in Arabic',
    (tester) async {
      await resetScopeGetIt();
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: true,
        ),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          QuranSessionsPlatformConfig(
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

      tester.view.physicalSize = const Size(360, 712);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final Widget? sliver = homeFeaturedTutorCardSliver(context);
              return CustomScrollView(
                slivers: [
                  ?sliver,
                  const SliverToBoxAdapter(child: SizedBox(height: 800)),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تعلّم القرآن مع محفظك'), findsOneWidget);
    },
  );

  testWidgets(
    'featured tutor card uses one kit interactive surface without ink wells',
    (tester) async {
      await resetScopeGetIt();
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: true,
        ),
      );
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          QuranSessionsPlatformConfig(
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

      await _pumpCard(tester);

      expect(find.byType(TilawaInteractiveSurface), findsOneWidget);
      expect(find.byType(TilawaButton), findsNothing);
      expect(find.text('My sessions'), findsNothing);
    },
  );

  testWidgets('featured tutor card exposes one button semantics target', (
    tester,
  ) async {
    await resetScopeGetIt();
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(
        quranSessionsEnabled: true,
        learnQuranStudentFeatureEnabled: true,
      ),
    );
    getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
      QuranSessionsPlatformConfigStore()..setConfig(
        QuranSessionsPlatformConfig(
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

    await _pumpCard(tester);

    expect(find.byType(TilawaButton), findsNothing);
    expect(find.text('My sessions'), findsNothing);

    final handle = tester.ensureSemantics();
    expect(_countSemanticsButtons(tester), 1);

    final cardSemantics = tester.getSemantics(find.text('Learn Quran'));
    expect(cardSemantics.flagsCollection.isButton, isTrue);
    expect(cardSemantics.hint, 'Start learning');
    handle.dispose();
  });

  testWidgets('logs card impression once and not again on rebuild', (
    tester,
  ) async {
    await resetScopeGetIt();
    final analytics = RecordingAnalyticsService();
    getIt
      ..registerSingleton<QuranSessionsPlatformConfigStore>(
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
      )
      ..registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: true,
        ),
      )
      ..registerSingleton<AnalyticsService>(analytics);

    await _pumpCard(tester);

    expect(
      analytics.events
          .where((e) => e == AnalyticsEvents.homeLearnQuranCardViewed)
          .length,
      1,
    );

    // Re-pump the equivalent tree: the element (and its State) is reused, so
    // the once-per-lifecycle guard keeps the impression from firing again.
    await _pumpCard(tester);

    expect(
      analytics.events
          .where((e) => e == AnalyticsEvents.homeLearnQuranCardViewed)
          .length,
      1,
    );
  });

  testWidgets('does not log impression until the card scrolls into view', (
    tester,
  ) async {
    await resetScopeGetIt();
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final analytics = RecordingAnalyticsService();
    getIt
      ..registerSingleton<QuranSessionsPlatformConfigStore>(
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
      )
      ..registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: true,
        ),
      )
      ..registerSingleton<AnalyticsService>(analytics);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: const [
              SizedBox(height: 1200),
              HomeFeaturedTutorCard(),
              SizedBox(height: 1200),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Card starts below the fold: render proxy would have logged, true
    // viewport tracking does not.
    expect(
      analytics.events.where(
        (e) => e == AnalyticsEvents.homeLearnQuranCardViewed,
      ),
      isEmpty,
    );

    controller.jumpTo(1200);
    await tester.pumpAndSettle();

    expect(
      analytics.events
          .where((e) => e == AnalyticsEvents.homeLearnQuranCardViewed)
          .length,
      1,
    );
  });

  testWidgets('does not log impression when feature flag is disabled', (
    tester,
  ) async {
    await resetScopeGetIt();
    final analytics = RecordingAnalyticsService();
    getIt
      ..registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: false,
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
      )
      ..registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(
          quranSessionsEnabled: true,
          learnQuranStudentFeatureEnabled: false,
        ),
      )
      ..registerSingleton<AnalyticsService>(analytics);

    await _pumpCard(tester);

    expect(analytics.events, isEmpty);
  });

  testWidgets('tapping the card logs the tap event', (tester) async {
    await resetScopeGetIt();
    final analytics = await _pumpRoutedCard(tester);

    await tester.tap(find.byType(TilawaInteractiveSurface));
    await tester.pumpAndSettle();

    expect(
      analytics.events,
      contains(AnalyticsEvents.homeLearnQuranCardTapped),
    );
  });
}
