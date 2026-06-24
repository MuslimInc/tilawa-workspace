import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';
import 'package:tilawa/features/qibla/presentation/bloc/qibla_bloc.dart';

void main() {
  group('QiblaEvent', () {
    const direction = QiblaDirectionEntity(
      qibla: 1,
      direction: 90,
      offset: 136,
    );

    test('marker events have empty props', () {
      expect(const CheckLocationService().props, isEmpty);
      expect(const RequestLocationPermission().props, isEmpty);
      expect(const StartQiblaStream().props, isEmpty);
      expect(const StopQiblaStream().props, isEmpty);
    });

    test('UpdateQiblaDirection props include direction', () {
      expect(
        const UpdateQiblaDirection(direction).props,
        [direction],
      );
    });

    test('QiblaErrorOccurred props include message', () {
      expect(
        const QiblaErrorOccurred('sensor failed').props,
        ['sensor failed'],
      );
    });
  });
}
