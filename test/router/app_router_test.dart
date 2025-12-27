import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router.dart';

import 'router_mock_helper.mocks.dart';

void main() {
  late MockGoRouterState mockGoRouterState;

  setUp(() {
    AppRouter.init(); // Register JSON types
    mockGoRouterState = MockGoRouterState();
    when(mockGoRouterState.uri).thenReturn(Uri.parse('/test'));
  });

  group('AppRouter', () {
    test('redirect returns null', () {
      final context = MockBuildContext();
      final String? result = AppRouter.redirect(context, mockGoRouterState);
      expect(result, isNull);
    });

    testWidgets('errorBuilder builds Scaffold with error information', (
      tester,
    ) async {
      final state = MockGoRouterState();
      when(state.uri).thenReturn(Uri.parse('/not-found'));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return AppRouter.errorBuilder(context, state);
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.textContaining('/not-found'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('errorBuilder Go Home navigation works', (tester) async {
      final router = GoRouter(
        initialLocation: '/non-existent',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Text('Home')),
        ],
        errorBuilder: AppRouter.errorBuilder,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);

      // Tap Go Home button (line 27)
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    test('navigatorKey is initialized', () {
      expect(AppRouter.navigatorKey, isNotNull);
    });

    test('router is initialized', () {
      expect(AppRouter.router, isNotNull);
    });

    test('extraCodec supports ReciterEntity serialization', () {
      const codec = AppRouterExtraCodec();

      const reciter = ReciterEntity(
        id: 1,
        name: 'Test',
        letter: 'T',
        date: '2024-01-01',
        moshaf: [],
      );

      final Object? encoded = codec.encoder.convert(reciter);
      expect(encoded, isA<Map<String, dynamic>>()); // Should be json map

      final Object? decoded = codec.decoder.convert(encoded);
      expect(decoded, reciter);
    });

    test('extraCodec handles null', () {
      const codec = AppRouterExtraCodec();
      expect(codec.encoder.convert(null), isNull);
      expect(codec.decoder.convert(null), isNull);
    });

    test('extraCodec passes through unknown tokens', () {
      const codec = AppRouterExtraCodec();
      const token = 'some-string';
      expect(codec.encoder.convert(token), token);
      expect(codec.decoder.convert(token), token);
    });
  });
}

class MockBuildContext extends Mock implements BuildContext {}
