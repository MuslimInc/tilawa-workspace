import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_alerts_permission_onboarding_repository.dart';
import 'package:tilawa/features/prayer_times/domain/value_objects/prayer_alarm_capability.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/prayer_alerts_permission_navigation.dart';
import 'package:tilawa/features/prayer_times/presentation/screens/prayer_alerts_permission_screen.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_alerts_permission_flow.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_navigator_keys.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/prayer_alerts_permission_nav_extra.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'fakes/fake_prayer_permissions_cubit.dart';

const Key _loginPageKey = Key('login-page');
const Key _onboardingPageKey = Key('onboarding-page');

class _FakeOnboardingRepository
    implements PrayerAlertsPermissionOnboardingRepository {
  _FakeOnboardingRepository() : completed = false;

  bool completed;
  int markCompletedCalls = 0;

  @override
  Future<bool> wasFlowCompleted() async => completed;

  @override
  Future<void> markFlowCompleted() async {
    markCompletedCalls++;
    completed = true;
  }
}

class _MockPrayerTimesBloc extends Mock implements PrayerTimesBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final GetIt getIt = GetIt.instance;
  late _FakeOnboardingRepository onboardingRepository;
  late FakePrayerPermissionsCubit permissionsCubit;

  setUpAll(() {
    registerFallbackValue(const PrayerTimesEvent.loadPrayerTimes());
  });

  setUp(() async {
    await getIt.reset();
    onboardingRepository = _FakeOnboardingRepository();
    permissionsCubit = FakePrayerPermissionsCubit(
      const PrayerPermissionsState(),
    );

    getIt.registerSingleton<PrayerAlertsPermissionOnboardingRepository>(
      onboardingRepository,
    );
    getIt.registerSingleton<PrayerPermissionsCubit>(permissionsCubit);
  });

  tearDown(() async {
    if (!permissionsCubit.isClosed) {
      await permissionsCubit.close();
    }
    await getIt.reset();
  });

  Widget buildNavigationApp({
    required FakePrayerPermissionsCubit cubit,
    PrayerPermissionsCubit? scopedCubit,
    PrayerTimesBloc? prayerTimesBloc,
    Future<void> Function(BuildContext context)? onShowAfterOnboarding,
    Future<void> Function(BuildContext context)? onShowIfNeeded,
    Future<void> Function(BuildContext context)? onShow,
  }) {
    addTearDown(cubit.close);

    final GoRouter router = GoRouter(
      navigatorKey: appRootNavigatorKey,
      initialLocation: '/onboarding',
      routes: <RouteBase>[
        GoRoute(
          path: '/onboarding',
          builder: (BuildContext context, GoRouterState state) {
            return Scaffold(
              key: _onboardingPageKey,
              body: Column(
                children: <Widget>[
                  if (onShowAfterOnboarding != null)
                    TextButton(
                      onPressed: () => onShowAfterOnboarding(context),
                      child: const Text('show-after-onboarding'),
                    ),
                  if (onShowIfNeeded != null)
                    TextButton(
                      onPressed: () => onShowIfNeeded(context),
                      child: const Text('show-if-needed'),
                    ),
                  if (onShow != null)
                    TextButton(
                      onPressed: () => onShow(context),
                      child: const Text('show-explicit'),
                    ),
                ],
              ),
            );
          },
        ),
        GoRoute(
          path: '/prayer-alerts-permissions',
          builder: (BuildContext context, GoRouterState state) {
            final PrayerAlertsPermissionNavExtra? extra =
                state.extra as PrayerAlertsPermissionNavExtra?;
            Widget child = BlocProvider<PrayerPermissionsCubit>.value(
              value: scopedCubit ?? cubit,
              child: PrayerAlertsPermissionScreen(navExtra: extra),
            );
            if (scopedCubit != null) {
              child = Provider<PrayerPermissionsCubit?>.value(
                value: scopedCubit,
                child: child,
              );
            }
            if (prayerTimesBloc != null) {
              child = Provider<PrayerTimesBloc?>.value(
                value: prayerTimesBloc,
                child: child,
              );
            }
            return child;
          },
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(
              key: _loginPageKey,
              body: Text('Login'),
            );
          },
        ),
      ],
    );

    Widget app = MaterialApp.router(
      theme: AppTheme.getLightTheme(
        primaryColor: PrimaryColorPreset.defaultPreset.value,
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      routerConfig: router,
    );

    if (prayerTimesBloc != null) {
      app = Provider<PrayerTimesBloc?>.value(
        value: prayerTimesBloc,
        child: app,
      );
    }

    return app;
  }

  Future<void> pumpNavigationApp(
    WidgetTester tester, {
    required FakePrayerPermissionsCubit cubit,
    PrayerPermissionsCubit? scopedCubit,
    PrayerTimesBloc? prayerTimesBloc,
    Future<void> Function(BuildContext context)? onShowAfterOnboarding,
    Future<void> Function(BuildContext context)? onShowIfNeeded,
    Future<void> Function(BuildContext context)? onShow,
  }) async {
    await tester.pumpWidget(
      buildNavigationApp(
        cubit: cubit,
        scopedCubit: scopedCubit,
        prayerTimesBloc: prayerTimesBloc,
        onShowAfterOnboarding: onShowAfterOnboarding,
        onShowIfNeeded: onShowIfNeeded,
        onShow: onShow,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('PrayerAlertsPermissionNavigation', () {
    testWidgets('showAfterOnboarding skips push when no steps are pending', (
      WidgetTester tester,
    ) async {
      permissionsCubit.emit(
        const PrayerPermissionsState(
          hasLocationPermission: true,
          capability: PrayerAlarmCapability(
            canScheduleExact: true,
            hasNotificationPermission: true,
          ),
        ),
      );

      await pumpNavigationApp(
        tester,
        cubit: permissionsCubit,
        onShowAfterOnboarding:
            PrayerAlertsPermissionNavigation.showAfterOnboarding,
      );

      await tester.tap(find.text('show-after-onboarding'));
      await tester.pumpAndSettle();

      expect(find.byKey(_onboardingPageKey), findsOneWidget);
      expect(find.byType(PrayerAlertsPermissionFlow), findsNothing);
      expect(onboardingRepository.markCompletedCalls, 1);
      expect(onboardingRepository.completed, isTrue);
    });

    testWidgets(
      'showAfterOnboarding pushes flow that continues to login on finish',
      (WidgetTester tester) async {
        permissionsCubit.emit(
          const PrayerPermissionsState(
            hasLocationPermission: false,
          ),
        );

        await pumpNavigationApp(
          tester,
          cubit: permissionsCubit,
          onShowAfterOnboarding:
              PrayerAlertsPermissionNavigation.showAfterOnboarding,
        );

        await tester.tap(find.text('show-after-onboarding'));
        await tester.pumpAndSettle();

        expect(find.byType(PrayerAlertsPermissionFlow), findsOneWidget);
        expect(find.byKey(_onboardingPageKey), findsNothing);

        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(find.byKey(_loginPageKey), findsOneWidget);
        expect(find.byKey(_onboardingPageKey), findsNothing);
        expect(onboardingRepository.markCompletedCalls, 1);
      },
    );

    testWidgets('showIfNeeded does nothing when flow was already completed', (
      WidgetTester tester,
    ) async {
      onboardingRepository.completed = true;
      permissionsCubit.emit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
        ),
      );

      await pumpNavigationApp(
        tester,
        cubit: permissionsCubit,
        onShowIfNeeded: PrayerAlertsPermissionNavigation.showIfNeeded,
      );

      await tester.tap(find.text('show-if-needed'));
      await tester.pumpAndSettle();

      expect(find.byKey(_onboardingPageKey), findsOneWidget);
      expect(find.byType(PrayerAlertsPermissionFlow), findsNothing);
      expect(onboardingRepository.markCompletedCalls, 0);
    });

    testWidgets('show pops back instead of going to login', (
      WidgetTester tester,
    ) async {
      permissionsCubit.emit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
          capability: PrayerAlarmCapability(
            canScheduleExact: false,
            hasNotificationPermission: false,
          ),
        ),
      );

      await pumpNavigationApp(
        tester,
        cubit: permissionsCubit,
        onShow: (BuildContext context) {
          return PrayerAlertsPermissionNavigation.show(
            context,
            steps: const <PrayerAlertsPermissionStep>[
              PrayerAlertsPermissionStep.location,
            ],
          );
        },
      );

      await tester.tap(find.text('show-explicit'));
      await tester.pumpAndSettle();

      expect(find.byType(PrayerAlertsPermissionFlow), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byKey(_onboardingPageKey), findsOneWidget);
      expect(find.byKey(_loginPageKey), findsNothing);
      expect(onboardingRepository.markCompletedCalls, 0);
    });

    testWidgets('showIfNeeded marks flow completed after returning', (
      WidgetTester tester,
    ) async {
      permissionsCubit.emit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
        ),
      );

      await pumpNavigationApp(
        tester,
        cubit: permissionsCubit,
        onShowIfNeeded: PrayerAlertsPermissionNavigation.showIfNeeded,
      );

      await tester.tap(find.text('show-if-needed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byKey(_onboardingPageKey), findsOneWidget);
      expect(onboardingRepository.markCompletedCalls, 1);
    });

    testWidgets('uses scoped PrayerPermissionsCubit when provided', (
      WidgetTester tester,
    ) async {
      final FakePrayerPermissionsCubit scopedCubit =
          FakePrayerPermissionsCubit(
            const PrayerPermissionsState(
              hasLocationPermission: false,
            ),
          );
      addTearDown(scopedCubit.close);

      await pumpNavigationApp(
        tester,
        cubit: permissionsCubit,
        scopedCubit: scopedCubit,
        onShowAfterOnboarding:
            PrayerAlertsPermissionNavigation.showAfterOnboarding,
      );

      await tester.tap(find.text('show-after-onboarding'));
      await tester.pumpAndSettle();

      expect(find.byType(PrayerAlertsPermissionFlow), findsOneWidget);
      expect(scopedCubit.state.hasLocationPermission, isFalse);
    });

    testWidgets('showIfNeededAfterLaunch delegates to showIfNeeded', (
      WidgetTester tester,
    ) async {
      permissionsCubit.emit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
        ),
      );

      await pumpNavigationApp(
        tester,
        cubit: permissionsCubit,
        onShowIfNeeded:
            PrayerAlertsPermissionNavigation.showIfNeededAfterLaunch,
      );

      await tester.tap(find.text('show-if-needed'));
      await tester.pumpAndSettle();

      expect(find.byType(PrayerAlertsPermissionFlow), findsOneWidget);
    });

    testWidgets('showIfNeeded refreshes prayer schedule after returning', (
      WidgetTester tester,
    ) async {
      final _MockPrayerTimesBloc prayerTimesBloc = _MockPrayerTimesBloc();
      when(
        () => prayerTimesBloc.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(() => prayerTimesBloc.state).thenReturn(const PrayerTimesState());
      when(() => prayerTimesBloc.add(any())).thenReturn(null);

      permissionsCubit.emit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
        ),
      );

      await pumpNavigationApp(
        tester,
        cubit: permissionsCubit,
        scopedCubit: permissionsCubit,
        prayerTimesBloc: prayerTimesBloc,
        onShowIfNeeded: PrayerAlertsPermissionNavigation.showIfNeeded,
      );

      await tester.tap(find.text('show-if-needed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      verify(
        () => prayerTimesBloc.add(
          const PrayerTimesEvent.loadPrayerTimes(forceReschedule: true),
        ),
      ).called(1);
    });
  });

  group('PrayerAlertsPermissionRoute payload', () {
    test('passes continueToLoginOnFinish through nav extra', () {
      const PrayerAlertsPermissionRoute route = PrayerAlertsPermissionRoute(
        $extra: PrayerAlertsPermissionNavExtra(
          steps: <PrayerAlertsPermissionStep>[
            PrayerAlertsPermissionStep.location,
          ],
          continueToLoginOnFinish: true,
        ),
      );

      expect(route.$extra?.continueToLoginOnFinish, isTrue);
      expect(route.$extra?.steps, hasLength(1));
    });
  });
}
