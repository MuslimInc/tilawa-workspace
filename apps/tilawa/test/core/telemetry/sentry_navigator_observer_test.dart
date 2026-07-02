import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/sentry_navigator_observer.dart';

void main() {
  group('TilawaSentryNavigatorObserver', () {
    test('create returns SentryNavigatorObserver', () {
      expect(
        TilawaSentryNavigatorObserver.create(),
        isA<SentryNavigatorObserver>(),
      );
    });

    test('ignores startup splash route', () {
      expect(
        TilawaSentryNavigatorObserver.ignoredRoutes,
        contains('/splash'),
      );
    });
  });
}
