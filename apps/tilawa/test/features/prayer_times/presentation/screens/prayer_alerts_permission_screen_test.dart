import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_alerts_permission_onboarding_repository.dart';
import 'package:tilawa/features/prayer_times/domain/value_objects/prayer_alarm_capability.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa/features/prayer_times/presentation/screens/prayer_alerts_permission_screen.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_alerts_permission_flow.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/prayer_alerts_permission_nav_extra.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

const Key _loginPageKey = Key('login-page');
const Key _onboardingPageKey = Key('onboarding-page');

class _FakePrayerPermissionsCubit extends Cubit<PrayerPermissionsState>
    implements PrayerPermissionsCubit {
  _FakePrayerPermissionsCubit(super.initial);

  @override
  Future<void> checkCapability() async {}

  @override
  Future<void> requestLocationPermission() async {}

  @override
  Future<void> requestExactAlarmPermission() async {}

  @override
  Future<void> requestNotificationPermission() async {}

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {}
}

class _FakeOnboardingRepository
    implements PrayerAlertsPermissionOnboardingRepository {
  @override
  Future<bool> wasFlowCompleted() async => false;

  @override
  Future<void> markFlowCompleted() async {}
}

class _TrackingOnboardingRepository
    implements PrayerAlertsPermissionOnboardingRepository {
  int markCompletedCalls = 0;

  @override
  Future<bool> wasFlowCompleted() async => false;

  @override
  Future<void> markFlowCompleted() async {
    markCompletedCalls++;
  }
}

Future<void> _pumpPermissionScreen(
  WidgetTester tester, {
  required _FakePrayerPermissionsCubit cubit,
  PrayerAlertsPermissionNavExtra? navExtra,
  bool continueToLoginOnFinish = false,
  String initialLocation = '/permissions',
}) async {
  addTearDown(cubit.close);

  final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            key: _onboardingPageKey,
            body: Text('Onboarding'),
          );
        },
      ),
      GoRoute(
        path: '/permissions',
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<PrayerPermissionsCubit>.value(
            value: cubit,
            child: PrayerAlertsPermissionScreen(
              navExtra:
                  navExtra ??
                  PrayerAlertsPermissionNavExtra(
                    steps: const <PrayerAlertsPermissionStep>[
                      PrayerAlertsPermissionStep.location,
                    ],
                    continueToLoginOnFinish: continueToLoginOnFinish,
                  ),
            ),
          );
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

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.getLightTheme(
        primaryColor: PrimaryColorPreset.defaultPreset.value,
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

class _PermissionScreenHarness extends StatefulWidget {
  const _PermissionScreenHarness({required this.cubit});

  final _FakePrayerPermissionsCubit cubit;

  @override
  State<_PermissionScreenHarness> createState() =>
      _PermissionScreenHarnessState();
}

class _PermissionScreenHarnessState extends State<_PermissionScreenHarness> {
  PrayerAlertsPermissionNavExtra? extra;

  void updateExtra(PrayerAlertsPermissionNavExtra? value) {
    setState(() {
      extra = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.getLightTheme(
        primaryColor: PrimaryColorPreset.defaultPreset.value,
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      home: BlocProvider<PrayerPermissionsCubit>.value(
        value: widget.cubit,
        child: PrayerAlertsPermissionScreen(navExtra: extra),
      ),
    );
  }
}

void main() {
  final GetIt getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<PrayerAlertsPermissionOnboardingRepository>(
      _FakeOnboardingRepository(),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('PrayerAlertsPermissionScreen exit navigation', () {
    testWidgets('places primary action above skip in the footer', (
      WidgetTester tester,
    ) async {
      final _FakePrayerPermissionsCubit cubit = _FakePrayerPermissionsCubit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
          capability: PrayerAlarmCapability(
            canScheduleExact: false,
            hasNotificationPermission: false,
          ),
        ),
      );

      await _pumpPermissionScreen(
        tester,
        cubit: cubit,
      );

      final Rect allow = tester.getRect(find.text('Allow'));
      final Rect skip = tester.getRect(find.text('Skip'));

      expect(allow.bottom, lessThan(skip.top));
      expect(allow.center.dy, lessThan(skip.center.dy));
    });

    testWidgets('skip on last step goes to login after onboarding', (
      WidgetTester tester,
    ) async {
      final _FakePrayerPermissionsCubit cubit = _FakePrayerPermissionsCubit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
          capability: PrayerAlarmCapability(
            canScheduleExact: false,
            hasNotificationPermission: false,
          ),
        ),
      );

      await _pumpPermissionScreen(
        tester,
        cubit: cubit,
        continueToLoginOnFinish: true,
      );

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byKey(_loginPageKey), findsOneWidget);
      expect(find.byKey(_onboardingPageKey), findsNothing);
    });

    testWidgets('skip on last step pops when not continuing to login', (
      WidgetTester tester,
    ) async {
      final _FakePrayerPermissionsCubit cubit = _FakePrayerPermissionsCubit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
          capability: PrayerAlarmCapability(
            canScheduleExact: false,
            hasNotificationPermission: false,
          ),
        ),
      );

      final GoRouter router = GoRouter(
        initialLocation: '/onboarding',
        routes: <RouteBase>[
          GoRoute(
            path: '/onboarding',
            builder: (BuildContext context, GoRouterState state) {
              return const Scaffold(
                key: _onboardingPageKey,
                body: Text('Onboarding'),
              );
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'permissions',
                builder: (BuildContext context, GoRouterState state) {
                  return BlocProvider<PrayerPermissionsCubit>.value(
                    value: cubit,
                    child: const PrayerAlertsPermissionScreen(
                      navExtra: PrayerAlertsPermissionNavExtra(
                        steps: <PrayerAlertsPermissionStep>[
                          PrayerAlertsPermissionStep.location,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.getLightTheme(
            primaryColor: PrimaryColorPreset.defaultPreset.value,
          ),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      );
      router.push('/onboarding/permissions');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byKey(_onboardingPageKey), findsOneWidget);
      expect(find.byType(PrayerAlertsPermissionFlow), findsNothing);
    });

    testWidgets('empty resolved steps go to login after onboarding', (
      WidgetTester tester,
    ) async {
      final _FakePrayerPermissionsCubit cubit = _FakePrayerPermissionsCubit(
        const PrayerPermissionsState(
          hasLocationPermission: true,
          capability: PrayerAlarmCapability(
            canScheduleExact: true,
            hasNotificationPermission: true,
          ),
        ),
      );

      await _pumpPermissionScreen(
        tester,
        cubit: cubit,
        navExtra: const PrayerAlertsPermissionNavExtra(
          continueToLoginOnFinish: true,
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byKey(_loginPageKey), findsOneWidget);
    });

    testWidgets('empty resolved steps pop when not continuing to login', (
      WidgetTester tester,
    ) async {
      final _FakePrayerPermissionsCubit cubit = _FakePrayerPermissionsCubit(
        const PrayerPermissionsState(
          hasLocationPermission: true,
          capability: PrayerAlarmCapability(
            canScheduleExact: true,
            hasNotificationPermission: true,
          ),
        ),
      );

      final GoRouter router = GoRouter(
        initialLocation: '/onboarding',
        routes: <RouteBase>[
          GoRoute(
            path: '/onboarding',
            builder: (BuildContext context, GoRouterState state) {
              return const Scaffold(
                key: _onboardingPageKey,
                body: Text('Onboarding'),
              );
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'permissions',
                builder: (BuildContext context, GoRouterState state) {
                  return BlocProvider<PrayerPermissionsCubit>.value(
                    value: cubit,
                    child: const PrayerAlertsPermissionScreen(),
                  );
                },
              ),
            ],
          ),
        ],
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.getLightTheme(
            primaryColor: PrimaryColorPreset.defaultPreset.value,
          ),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      );
      router.push('/onboarding/permissions');
      await tester.pumpAndSettle();

      await tester.pump();
      await tester.pump();

      expect(find.byKey(_onboardingPageKey), findsOneWidget);
    });

    testWidgets('pins steps from nav extra for the full wizard session', (
      WidgetTester tester,
    ) async {
      final _FakePrayerPermissionsCubit cubit = _FakePrayerPermissionsCubit(
        const PrayerPermissionsState(
          hasLocationPermission: true,
          capability: PrayerAlarmCapability(
            canScheduleExact: true,
            hasNotificationPermission: true,
          ),
        ),
      );

      await _pumpPermissionScreen(
        tester,
        cubit: cubit,
        navExtra: const PrayerAlertsPermissionNavExtra(
          steps: <PrayerAlertsPermissionStep>[
            PrayerAlertsPermissionStep.notifications,
          ],
        ),
      );

      expect(find.byType(PrayerAlertsPermissionFlow), findsOneWidget);
      expect(find.text('Allow notifications'), findsOneWidget);
    });

    testWidgets('pins steps when nav extra arrives after first frame', (
      WidgetTester tester,
    ) async {
      final _FakePrayerPermissionsCubit cubit = _FakePrayerPermissionsCubit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
        ),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        _PermissionScreenHarness(cubit: cubit),
      );
      await tester.pump();

      final _PermissionScreenHarnessState harnessState = tester
          .state<_PermissionScreenHarnessState>(
            find.byType(_PermissionScreenHarness),
          );
      harnessState.updateExtra(
        const PrayerAlertsPermissionNavExtra(
          steps: <PrayerAlertsPermissionStep>[
            PrayerAlertsPermissionStep.location,
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('rebuilds derived steps when capability resolves', (
      WidgetTester tester,
    ) async {
      final _FakePrayerPermissionsCubit cubit = _FakePrayerPermissionsCubit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
        ),
      );

      await _pumpPermissionScreen(
        tester,
        cubit: cubit,
        navExtra: const PrayerAlertsPermissionNavExtra(),
      );

      expect(find.text('Location'), findsOneWidget);

      cubit.emit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
          capability: PrayerAlarmCapability(
            canScheduleExact: false,
            hasNotificationPermission: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Allow notifications'), findsOneWidget);
    });

    testWidgets('rebuilds when location permission state changes', (
      WidgetTester tester,
    ) async {
      final _FakePrayerPermissionsCubit cubit = _FakePrayerPermissionsCubit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
          capability: PrayerAlarmCapability(
            canScheduleExact: true,
            hasNotificationPermission: false,
          ),
        ),
      );

      await _pumpPermissionScreen(
        tester,
        cubit: cubit,
        navExtra: const PrayerAlertsPermissionNavExtra(),
      );

      expect(find.text('Location'), findsOneWidget);

      cubit.emit(
        const PrayerPermissionsState(
          hasLocationPermission: true,
          capability: PrayerAlarmCapability(
            canScheduleExact: true,
            hasNotificationPermission: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Allow notifications'), findsOneWidget);
      expect(find.text('Location'), findsNothing);
    });

    testWidgets('marks onboarding complete before navigating to login', (
      WidgetTester tester,
    ) async {
      final _TrackingOnboardingRepository repository =
          _TrackingOnboardingRepository();
      await getIt.reset();
      getIt.registerSingleton<PrayerAlertsPermissionOnboardingRepository>(
        repository,
      );

      final _FakePrayerPermissionsCubit cubit = _FakePrayerPermissionsCubit(
        const PrayerPermissionsState(
          hasLocationPermission: false,
        ),
      );

      await _pumpPermissionScreen(
        tester,
        cubit: cubit,
        continueToLoginOnFinish: true,
      );

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(repository.markCompletedCalls, 1);
      expect(find.byKey(_loginPageKey), findsOneWidget);
    });
  });
}
