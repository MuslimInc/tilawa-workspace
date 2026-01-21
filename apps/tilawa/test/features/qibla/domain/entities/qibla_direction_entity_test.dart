import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';

void main() {
  group('QiblaDirectionEntity', () {
    test('isAligned returns true when difference is less than 2 degrees', () {
      const offset = 100.0;
      const entity = QiblaDirectionEntity(
        qibla: 0,
        direction: 101.5, // 1.5 degrees diff
        offset: offset,
      );

      expect(entity.isAligned, true);
    });

    test('isAligned returns true when difference is exactly 0', () {
      const offset = 100.0;
      const entity = QiblaDirectionEntity(
        qibla: 0,
        direction: 100.0,
        offset: offset,
      );

      expect(entity.isAligned, true);
    });

    test('isAligned returns false when difference is exactly 2 degrees', () {
      const offset = 100.0;
      const entity = QiblaDirectionEntity(
        qibla: 0,
        direction: 102.0,
        offset: offset,
      );

      expect(entity.isAligned, false);
    });

    test(
      'isAligned returns true when difference is > 358 (crossing 0/360 boundary)',
      () {
        // Qibla at 10 degrees, Direction at 359 degrees (effectively -1 degree)
        // Wait, the logic is (direction - qibla).abs().
        // If Qibla is 5 and Direction is 359.
        // 359 - 5 = 354. abs is 354.
        // 354 > 358? No.
        // The logic `diff > 358` handles the wrap around if the values are normalized 0-360.

        // Example: Qibla = 0, Direction = 359. Diff = 359. 359 > 358 -> True.
        const entity = QiblaDirectionEntity(
          qibla: 0,
          direction: 359,
          offset: 0,
        );

        expect(entity.isAligned, true);
      },
    );

    test('isAligned returns true when difference is > 358 (reverse)', () {
      // Qibla = 359, Direction = 0. Diff = 359. 359 > 358 -> True.
      const entity = QiblaDirectionEntity(qibla: 0, direction: 0, offset: 359);

      expect(entity.isAligned, true);
    });

    test('isAligned returns false when difference is significant', () {
      const offset = 100.0;
      const entity = QiblaDirectionEntity(
        qibla: 0,
        direction: 150.0,
        offset: offset,
      );

      expect(entity.isAligned, false);
    });
  });
}
