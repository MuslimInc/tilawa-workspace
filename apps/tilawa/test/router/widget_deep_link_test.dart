import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/router/app_router_config.dart';

void main() {
  group('WidgetActionRoute redirection', () {
    test('prayer routes redirect to PrayerTimesRoute', () {
      final route = const WidgetActionRoute(action: 'prayer');
      final redirectPath = route.redirect(
        _mockContext(),
        _mockState('/widget/prayer'),
      );
      expect(redirectPath, '/prayer-times');
      
      final route2 = const WidgetActionRoute(action: 'prayer-times');
      final redirectPath2 = route2.redirect(
        _mockContext(),
        _mockState('/widget/prayer-times'),
      );
      expect(redirectPath2, '/prayer-times');
    });

    test('ayah routes redirect to QuranReaderRoute or index', () {
      final route = const WidgetActionRoute(action: 'ayah', id: '114');
      final redirectPath = route.redirect(
        _mockContext(),
        _mockState('/widget/ayah?ayah=5'),
      );
      expect(redirectPath, '/quran-reader/114');
      
      final routeFallback = const WidgetActionRoute(action: 'ayah');
      final redirectFallback = routeFallback.redirect(
        _mockContext(),
        _mockState('/widget/ayah'),
      );
      expect(redirectFallback, '/quran-index');
    });

    test('athkar routes redirect to AthkarCategoriesRoute', () {
      final route = const WidgetActionRoute(action: 'athkar');
      final redirectPath = route.redirect(
        _mockContext(),
        _mockState('/widget/athkar'),
      );
      expect(redirectPath, '/athkar');
    });

    test('hijri routes redirect to SettingsRoute', () {
      final route = const WidgetActionRoute(action: 'hijri');
      final redirectPath = route.redirect(
        _mockContext(),
        _mockState('/widget/hijri'),
      );
      expect(redirectPath, '/settings');
    });

    test('unknown actions fallback to HomeRoute', () {
      final route = const WidgetActionRoute(action: 'unknown_stuff');
      final redirectPath = route.redirect(
        _mockContext(),
        _mockState('/widget/unknown_stuff'),
      );
      expect(redirectPath, '/');
    });
  });
}

BuildContext _mockContext() => null as dynamic;

GoRouterState _mockState(String uriStr) {
  final uri = Uri.parse(uriStr);
  return GoRouterState(
    null as dynamic,
    uri: uri,
    matchedLocation: uri.path,
    name: null,
    path: uri.path,
    fullPath: uri.path,
    pathParameters: const {},
    extra: null,
    pageKey: const ValueKey('mock'),
  );
}
