import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';

void main() {
  test('QiblaDirectionEntity supports value equality', () {
    const entity1 = QiblaDirectionEntity(qibla: 100, direction: 90, offset: 10);
    const entity2 = QiblaDirectionEntity(qibla: 100, direction: 90, offset: 10);
    const entity3 = QiblaDirectionEntity(qibla: 101, direction: 90, offset: 10);

    expect(entity1, equals(entity2));
    expect(entity1, isNot(equals(entity3)));
  });
}
