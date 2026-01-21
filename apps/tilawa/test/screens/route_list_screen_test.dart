import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/screens/route_list_screen.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  testWidgets('RouteListScreen displays routes and handles navigation', (
    tester,
  ) async {
    // Using a real GoRouter to avoid complexity of mocking internal state for context.push
    final router = GoRouter(
      initialLocation: '/routes',
      routes: [
        GoRoute(
          path: '/routes',
          builder: (context, state) => const RouteListScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) =>
              const Scaffold(body: Text('Settings Page')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('All Routes'), findsOneWidget);

    // Check for some known routes from $appRoutes (e.g., /settings)
    expect(find.text('/settings'), findsWidgets);

    // Check for parameterized routes (e.g., /reciter/:reciterId)
    expect(find.textContaining('/:'), findsWidgets);
    expect(find.text('Parameterized'), findsAtLeastNWidgets(1));

    // Tap a clickable route
    await tester.tap(find.text('/settings').first);
    await tester.pumpAndSettle();

    expect(find.text('Settings Page'), findsOneWidget);
  });

  testWidgets('RouteListScreen handles various route types in _getAllRoutes', (
    tester,
  ) async {
    // Mock routes to trigger logical branches in _getAllRoutes
    final List<RouteBase> mockRoutes = [
      GoRoute(path: '/', builder: (context, state) => const SizedBox()),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const SizedBox(),
        routes: [
          GoRoute(path: 'child', builder: (context, state) => const SizedBox()),
          GoRoute(
            path: '/absolute-child',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/shell',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => navigationShell,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/branch',
                builder: (context, state) => const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(home: RouteListScreen(routes: mockRoutes)),
    );

    expect(find.text('/'), findsOneWidget);
    expect(find.text('/parent'), findsOneWidget);
    expect(find.text('/parent/child'), findsOneWidget);
    expect(find.text('/parent/absolute-child'), findsOneWidget);
    expect(find.text('/shell'), findsOneWidget);
    expect(find.text('/branch'), findsOneWidget);
  });
}
