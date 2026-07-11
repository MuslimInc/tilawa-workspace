import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/router/app_router_config.dart';

class _MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('WidgetActionRoute redirection', () {
    testWidgets('prayer routes redirect to PrayerTimesRoute', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      const route = WidgetActionRoute(action: 'prayer');
      final redirectPath = route.redirect(
        context,
        _mockState('/widget/prayer'),
      );
      expect(redirectPath, '/prayer-times');

      const route2 = WidgetActionRoute(action: 'prayer-times');
      final redirectPath2 = route2.redirect(
        context,
        _mockState('/widget/prayer-times'),
      );
      expect(redirectPath2, '/prayer-times');
    });

    testWidgets('ayah routes redirect to QuranReaderRoute or index', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      const route = WidgetActionRoute(action: 'ayah', id: '114');
      final redirectPath = route.redirect(
        context,
        _mockState('/widget/ayah?ayah=5'),
      );
      expect(redirectPath, '/quran-reader/114?ayah-number=5');

      const routeFallback = WidgetActionRoute(action: 'ayah');
      final redirectFallback = routeFallback.redirect(
        context,
        _mockState('/widget/ayah'),
      );
      expect(redirectFallback, '/quran-index');
    });

    testWidgets('athkar routes redirect to AthkarCategoriesRoute', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      const route = WidgetActionRoute(action: 'athkar');
      final redirectPath = route.redirect(
        context,
        _mockState('/widget/athkar'),
      );
      expect(redirectPath, '/athkar');
    });

    testWidgets('hijri routes redirect to SettingsRoute', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      const route = WidgetActionRoute(action: 'hijri');
      final redirectPath = route.redirect(
        context,
        _mockState('/widget/hijri'),
      );
      expect(redirectPath, '/settings');
    });

    testWidgets('unknown actions fallback to HomeRoute', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      const route = WidgetActionRoute(action: 'unknown_stuff');
      final redirectPath = route.redirect(
        context,
        _mockState('/widget/unknown_stuff'),
      );
      expect(redirectPath, '/');
    });
  });
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (ctx) {
          context = ctx;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return context;
}

GoRouterState _mockState(String uriStr) {
  final uri = Uri.parse(uriStr);
  final state = _MockGoRouterState();
  when(() => state.uri).thenReturn(uri);
  return state;
}
