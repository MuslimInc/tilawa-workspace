import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/models/position_data.dart';
import 'package:tilawa/shared/widgets/quran_player_progress_display.dart';

void main() {
  group('resolvePlayerProgressTimes', () {
    test('shows elapsed and remaining when duration is valid', () {
      const PositionData data = PositionData(
        position: Duration(minutes: 5),
        bufferedPosition: Duration.zero,
        duration: Duration(minutes: 33),
      );

      final PlayerProgressTimes times = resolvePlayerProgressTimes(data);

      expect(times.elapsed, const Duration(minutes: 5));
      expect(times.remainingLabel, '−28:00');
    });

    test('clamps elapsed to duration when position overshoots', () {
      const PositionData data = PositionData(
        position: Duration(hours: 1, minutes: 17),
        bufferedPosition: Duration.zero,
        duration: Duration(minutes: 33),
      );

      final PlayerProgressTimes times = resolvePlayerProgressTimes(data);

      expect(times.elapsed, const Duration(minutes: 33));
      expect(times.remainingLabel, '−00:00');
    });

    test('handles overshoot when position exceeds duration', () {
      const PositionData data = PositionData(
        position: Duration(hours: 1),
        bufferedPosition: Duration.zero,
        duration: Duration(minutes: 10),
      );

      resolvePlayerProgressTimes(data);

      expect(data.position > data.duration, isTrue);
    });
  });
}
