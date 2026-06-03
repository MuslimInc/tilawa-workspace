import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/domain/resolve_media_session_update_position.dart';

void main() {
  group('resolveMediaSessionUpdatePosition', () {
    test('uses engine position when engine reports progress', () {
      expect(
        resolveMediaSessionUpdatePosition(
          enginePosition: const Duration(minutes: 25),
          previousUpdatePosition: const Duration(minutes: 10),
          playing: true,
          engineReady: true,
        ),
        const Duration(minutes: 25),
      );
    });

    test('keeps previous position when paused and engine reports zero', () {
      expect(
        resolveMediaSessionUpdatePosition(
          enginePosition: Duration.zero,
          previousUpdatePosition: const Duration(minutes: 47),
          playing: false,
          engineReady: true,
        ),
        const Duration(minutes: 47),
      );
    });

    test(
      'keeps previous position when resuming play before engine catches up',
      () {
        expect(
          resolveMediaSessionUpdatePosition(
            enginePosition: Duration.zero,
            previousUpdatePosition: const Duration(minutes: 47),
            playing: true,
            engineReady: true,
          ),
          const Duration(minutes: 47),
        );
      },
    );

    test('allows zero when nothing was played yet', () {
      expect(
        resolveMediaSessionUpdatePosition(
          enginePosition: Duration.zero,
          previousUpdatePosition: Duration.zero,
          playing: true,
          engineReady: true,
        ),
        Duration.zero,
      );
    });

    test('allows short previous position to reset on play', () {
      expect(
        resolveMediaSessionUpdatePosition(
          enginePosition: Duration.zero,
          previousUpdatePosition: const Duration(seconds: 30),
          playing: true,
          engineReady: true,
        ),
        Duration.zero,
      );
    });

    test('does not hold stale position while buffering', () {
      expect(
        resolveMediaSessionUpdatePosition(
          enginePosition: Duration.zero,
          previousUpdatePosition: const Duration(minutes: 47),
          playing: true,
          engineReady: false,
        ),
        Duration.zero,
      );
    });
  });
}
