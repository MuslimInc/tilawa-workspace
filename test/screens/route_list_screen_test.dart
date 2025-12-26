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
}
