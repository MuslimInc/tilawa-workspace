import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/qibla/domain/qibla_heading_math.dart';

void main() {
  group('shortestHeadingDelta', () {
    test('returns bearing minus heading when within +/-180', () {
      expect(
        shortestHeadingDelta(bearing: 136, heading: 0),
        136,
      );
      expect(
        shortestHeadingDelta(bearing: 136, heading: 90),
        46,
      );
    });

    test('wraps across the 0/360 boundary', () {
      expect(
        shortestHeadingDelta(bearing: 10, heading: 350),
        20,
      );
      expect(
        shortestHeadingDelta(bearing: 350, heading: 10),
        -20,
      );
    });

    test('returns 0 when heading matches bearing', () {
      expect(
        shortestHeadingDelta(bearing: 136, heading: 136),
        0,
      );
    });

    test('must use offset not package qibla field for needle rotation', () {
      const double offset = 136;

      double packageQiblaField(double heading) =>
          (heading + (360 - offset)) % 360;

      final double staleNeedleA = packageQiblaField(0) - 0;
      final double staleNeedleB = packageQiblaField(90) - 90;

      expect(staleNeedleA, staleNeedleB);

      expect(
        shortestHeadingDelta(bearing: offset, heading: 0),
        isNot(shortestHeadingDelta(bearing: offset, heading: 90)),
      );
    });
  });

  group('degreesToQiblaBearing', () {
    test('returns absolute shortest delta', () {
      expect(
        degreesToQiblaBearing(bearing: 10, heading: 350),
        20,
      );
      expect(
        degreesToQiblaBearing(bearing: 350, heading: 10),
        20,
      );
    });
  });

  group('isHeadingAlignedWithBearing', () {
    test('returns true within tolerance', () {
      expect(
        isHeadingAlignedWithBearing(bearing: 100, heading: 101.5),
        isTrue,
      );
    });

    test('returns false at exactly 2 degrees off', () {
      expect(
        isHeadingAlignedWithBearing(bearing: 100, heading: 102),
        isFalse,
      );
    });
  });
}
