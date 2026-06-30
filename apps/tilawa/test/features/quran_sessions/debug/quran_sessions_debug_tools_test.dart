import 'package:checks/checks.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/quran_sessions/debug/quran_sessions_debug_tools.dart';

void main() {
  group('isQuranSessionsDebugToolsVisible', () {
    test('visible in debug mode regardless of distribution', () {
      check(
        isQuranSessionsDebugToolsVisible(
          debugMode: true,
          distribution: 'play_production',
        ),
      ).isTrue();
    });

    test('visible in staging release builds', () {
      check(
        isQuranSessionsDebugToolsVisible(
          debugMode: false,
          distribution: 'staging',
        ),
      ).isTrue();
    });

    test('hidden in play_production release builds', () {
      check(
        isQuranSessionsDebugToolsVisible(
          debugMode: false,
          distribution: 'play_production',
        ),
      ).isFalse();
    });

    test('hidden in play_beta release builds', () {
      check(
        isQuranSessionsDebugToolsVisible(
          debugMode: false,
          distribution: 'play_beta',
        ),
      ).isFalse();
    });
  });

  group('isDebugLiveKitCallableAllowed', () {
    test('blocks play_production and play_alpha release tracks', () {
      check(
        isDebugLiveKitCallableAllowed(
          debugMode: false,
          distribution: 'play_production',
        ),
      ).isFalse();
      check(
        isDebugLiveKitCallableAllowed(
          debugMode: false,
          distribution: 'play_alpha',
        ),
      ).isFalse();
    });

    test('blocks play-track distributions even in debug mode', () {
      check(
        isDebugLiveKitCallableAllowed(
          debugMode: true,
          distribution: 'play_alpha',
        ),
      ).isFalse();
    });

    test('allows debug builds on local distribution', () {
      check(
        isDebugLiveKitCallableAllowed(
          debugMode: true,
          distribution: 'local',
        ),
      ).isTrue();
    });

    test('allows staging and local non-debug builds', () {
      check(
        isDebugLiveKitCallableAllowed(
          debugMode: false,
          distribution: 'staging',
        ),
      ).isTrue();
      check(
        isDebugLiveKitCallableAllowed(
          debugMode: false,
          distribution: 'local',
        ),
      ).isTrue();
    });
  });

  group('mapDebugLiveKitTokenCallableFailure', () {
    test('maps not-found to deploy hint reason', () {
      final failure = mapDebugLiveKitTokenCallableFailure(
        FirebaseFunctionsException(code: 'not-found', message: 'NOT_FOUND'),
      );

      check(failure).isA<RtcCallJoinFailure>();
      check(failure.reasonCode).equals('debug_callable_not_deployed');
    });

    test('maps permission-denied to unauthorized reason', () {
      final failure = mapDebugLiveKitTokenCallableFailure(
        FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'Denied',
        ),
      );

      check(failure.reasonCode).equals('debug_callable_unauthorized');
    });

    test('maps unauthenticated to unauthorized reason', () {
      final failure = mapDebugLiveKitTokenCallableFailure(
        FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'Authentication required.',
        ),
      );

      check(failure.reasonCode).equals('debug_callable_unauthorized');
    });
  });
}
