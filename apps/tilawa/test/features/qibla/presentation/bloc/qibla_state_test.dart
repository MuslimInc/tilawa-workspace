import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';
import 'package:tilawa/features/qibla/presentation/bloc/qibla_bloc.dart';

void main() {
  group('QiblaState', () {
    const direction = QiblaDirectionEntity(
      qibla: 1,
      direction: 90,
      offset: 136,
    );

    test('copyWith updates status and direction', () {
      const initial = QiblaState();
      final updated = initial.copyWith(
        status: QiblaStatus.success,
        direction: direction,
      );

      expect(updated.status, QiblaStatus.success);
      expect(updated.direction, direction);
      expect(updated.errorMessage, isNull);
    });

    test('copyWith clears errorMessage when explicitly set to null', () {
      const initial = QiblaState(
        status: QiblaStatus.error,
        errorMessage: 'failed',
      );

      expect(initial.copyWith(errorMessage: null).errorMessage, isNull);
    });

    test('props include status, direction, and errorMessage', () {
      const state = QiblaState(
        status: QiblaStatus.error,
        direction: direction,
        errorMessage: 'boom',
      );

      expect(state.props, [
        QiblaStatus.error,
        direction,
        'boom',
      ]);
    });
  });
}
