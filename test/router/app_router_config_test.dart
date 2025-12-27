import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/features/athkar/presentation/screens/athkar_categories_screen.dart';
import 'package:tilawa/features/athkar/presentation/screens/athkar_details_screen.dart';
import 'package:tilawa/features/auth/presentation/screens/login_screen.dart';
import 'package:tilawa/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:tilawa/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:tilawa/features/premium/presentation/screens/premium_screen.dart';
import 'package:tilawa/features/qibla/presentation/screens/qibla_screen.dart';
import 'package:tilawa/features/reciters/presentation/screens/favorites_screen.dart';
import 'package:tilawa/features/settings/presentation/screens/settings_screen.dart';
import 'package:tilawa/features/splash/presentation/screens/splash_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/screens/main_screen.dart';
import 'package:tilawa/screens/reciter_details_loader.dart';
import 'package:tilawa/screens/reciter_details_screen.dart';
import 'package:tilawa/screens/route_list_screen.dart';
import 'package:tilawa/shared/widgets/expanded_player_screen.dart';

import 'router_mock_helper.mocks.dart';

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockAudioPlayerBloc mockAudioPlayerBloc;
  late MockDownloadsBloc mockDownloadsBloc;
  late MockReciterDetailsLoaderCubit mockReciterDetailsLoaderCubit;
  late MockGoRouterState mockGoRouterState;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockAudioPlayerBloc = MockAudioPlayerBloc();
    mockDownloadsBloc = MockDownloadsBloc();
    mockReciterDetailsLoaderCubit = MockReciterDetailsLoaderCubit();
    mockGoRouterState = MockGoRouterState();

    when(mockGoRouterState.pageKey).thenReturn(const ValueKey('test'));
    when(mockGoRouterState.uri).thenReturn(Uri.parse('/test'));
  });

  group('AppRouterConfig Routes', () {
    test('HomeRoute builds MainScreen', () {
      const route = HomeRoute();
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<MainScreen>());
    });

    test('OnboardingRoute builds OnboardingScreen', () {
      const route = OnboardingRoute();
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<OnboardingScreen>());
    });

    group('ReciterDetailsRoute', () {
      const reciter = ReciterEntity(
        id: 1,
        name: 'Test Reciter',
        letter: 'T',
        date: '2023-01-01',
        moshaf: [],
      );

      test('builds ReciterDetailsLoader when extra is null', () {
        const route = ReciterDetailsRoute(reciterId: '1');
        final Widget widget = route.build(
          MockBuildContext(),
          mockGoRouterState,
        );
        expect(widget, isA<ReciterDetailsLoader>());
        expect((widget as ReciterDetailsLoader).reciterId, '1');
      });

      test('builds ReciterDetailsScreen when extra is present', () {
        const route = ReciterDetailsRoute(reciterId: '1', $extra: reciter);
        final Widget widget = route.build(
          MockBuildContext(),
          mockGoRouterState,
        );
        expect(widget, isA<ReciterDetailsScreen>());
        expect((widget as ReciterDetailsScreen).reciter, reciter);
      });
    });

    test('ExpandedPlayerRoute builds CustomTransitionPage', () {
      const route = ExpandedPlayerRoute();
      final Page<void> page = route.buildPage(
        MockBuildContext(),
        mockGoRouterState,
      );
      expect(page, isA<CustomTransitionPage>());
      final transitionPage = page as CustomTransitionPage;
      expect(transitionPage.child, isA<ExpandedPlayerScreen>());

      // Test transitionsBuilder (lines 71-72)
      final Widget transitionWidget = transitionPage.transitionsBuilder(
        MockBuildContext(),
        const AlwaysStoppedAnimation(1.0),
        const AlwaysStoppedAnimation(0.0),
        const SizedBox(),
      );
      expect(transitionWidget, isA<FadeTransition>());
    });

    test('PremiumRoute builds PremiumScreen', () {
      const route = PremiumRoute();
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<PremiumScreen>());
    });

    test('SettingsRoute builds SettingsScreen', () {
      const route = SettingsRoute();
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<SettingsScreen>());
    });

    test('LoginRoute builds LoginScreen', () {
      const route = LoginRoute();
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<LoginScreen>());
    });

    test('DownloadsRoute builds DownloadsScreen', () {
      const route = DownloadsRoute();
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<DownloadsScreen>());
    });

    test('FavoritesRoute builds FavoritesScreen', () {
      const route = FavoritesRoute();
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<FavoritesScreen>());
    });

    test('AthkarCategoriesRoute builds AthkarCategoriesScreen', () {
      const route = AthkarCategoriesRoute();
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<AthkarCategoriesScreen>());
    });

    test('AthkarDetailsRoute builds AthkarDetailsScreen', () {
      const route = AthkarDetailsRoute(categoryId: 1, categoryName: 'Test');
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<AthkarDetailsScreen>());
      expect((widget as AthkarDetailsScreen).categoryId, 1);
      expect(widget.categoryName, 'Test');
    });

    test('QiblaRoute builds QiblaScreen', () {
      const route = QiblaRoute();
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<QiblaScreen>());
    });

    test('RouteListRoute builds RouteListScreen', () {
      const route = RouteListRoute();
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<RouteListScreen>());
    });

    testWidgets('SplashRoute builds SplashScreen', (tester) async {
      const route = SplashRoute();
      final Widget widget = route.build(MockBuildContext(), mockGoRouterState);
      expect(widget, isA<SplashScreen>());
    });

    testWidgets('ErrorRoute builds Scaffold with error information', (
      tester,
    ) async {
      when(mockGoRouterState.uri).thenReturn(Uri.parse('/invalid-path'));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              const route = ErrorRoute(error: 'Test Error');
              return route.build(context, mockGoRouterState);
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('ErrorRoute navigation works', (tester) async {
      final router = GoRouter(
        initialLocation: '/error',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Text('Home')),
          GoRoute(
            path: '/error',
            builder: (context, state) =>
                const ErrorRoute().build(context, state),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );

      // Tap Go Home button (lines 135-138)
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });
}

class MockBuildContext extends Mock implements BuildContext {}
