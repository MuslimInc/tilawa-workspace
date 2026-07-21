import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_state.dart';

void main() {
  group('HomeListeningResumeState.resumeInitialPosition', () {
    test('returns last position for in-progress listening', () {
      const state = HomeListeningResumeState(
        lastPositionMs: 12000,
        durationMs: 44834,
      );

      expect(
        state.resumeInitialPosition,
        const Duration(milliseconds: 12000),
      );
    });

    test('returns null when completed so replay starts from beginning', () {
      const state = HomeListeningResumeState(
        lastPositionMs: 44826,
        durationMs: 44834,
        completed: true,
      );

      expect(state.resumeInitialPosition, isNull);
    });

    test('returns null when within 3% of end', () {
      const state = HomeListeningResumeState(
        lastPositionMs: 9800,
        durationMs: 10000,
      );

      expect(state.resumeInitialPosition, isNull);
    });

    test('returns null when last position is zero', () {
      const state = HomeListeningResumeState(
        lastPositionMs: 0,
        durationMs: 10000,
      );

      expect(state.resumeInitialPosition, isNull);
    });
  });
}
