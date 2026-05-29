import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/navigation/navigation_source.dart';

void main() {
  group('NavigationSource', () {
    test('exposes stable wire values', () {
      expect(NavigationSource.notification.wireValue, 'notification');
      expect(NavigationSource.deepLink.wireValue, 'deep_link');
      expect(NavigationSource.manual.wireValue, 'manual');
    });

    test('fromWire round-trips known values', () {
      for (final NavigationSource source in NavigationSource.values) {
        expect(NavigationSource.fromWire(source.wireValue), source);
      }
    });

    test('fromWire defaults to manual for unknown or null', () {
      expect(NavigationSource.fromWire('unknown'), NavigationSource.manual);
      expect(NavigationSource.fromWire(null), NavigationSource.manual);
    });
  });
}
