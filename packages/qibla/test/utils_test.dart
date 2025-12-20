import 'package:flutter_test/flutter_test.dart';
import 'package:qibla/src/utils.dart';

void main() {
  group('Utils', () {
    test('getOffsetFromNorth returns correct Qibla direction for London', () {
      // London coordinates: 51.5074 N, 0.1278 W
      final double qibla = Utils.getOffsetFromNorth(51.5074, -0.1278);
      expect(qibla, closeTo(119.1, 0.5));
    });

    test('getOffsetFromNorth returns correct Qibla direction for New York', () {
      // New York coordinates: 40.7128 N, 74.0060 W
      final double qibla = Utils.getOffsetFromNorth(40.7128, -74.0060);
      expect(qibla, closeTo(58.5, 0.5));
    });

    test('getOffsetFromNorth returns correct Qibla direction for Dubai', () {
      // Dubai coordinates: 25.2048 N, 55.2708 E
      final double qibla = Utils.getOffsetFromNorth(25.2048, 55.2708);
      expect(qibla, closeTo(258.2, 0.5));
    });

    test('getOffsetFromNorth returns correct Qibla direction for Sydney', () {
      // Sydney coordinates: 33.8688 S, 151.2093 E
      final double qibla = Utils.getOffsetFromNorth(-33.8688, 151.2093);
      expect(qibla, closeTo(277.5, 0.5));
    });

    test(
      "getOffsetFromNorth at Mecca (offset direction doesn't matter much)",
      () {
        // Mecca coordinates: 21.422487, 39.826206
        final double qibla = Utils.getOffsetFromNorth(21.4225, 39.8262);
        expect(qibla.isFinite, isTrue);
      },
    );
  });
}
