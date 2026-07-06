import 'package:checks/checks.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firebase_callable_failure_mapper.dart';

FirebaseFunctionsException _callable({
  required String code,
  String? message,
  Object? details,
}) {
  return FirebaseFunctionsException(
    code: code,
    message: message ?? '',
    details: details,
  );
}

void main() {
  test('maps already-exists to slot unavailable', () {
    final failure = mapQuranSessionsCallableFailure(
      _callable(code: 'already-exists'),
      slotId: 'teacher1_20260110T0700Z',
    );

    check(failure).isA<SlotUnavailableFailure>();
    check(
      (failure as SlotUnavailableFailure).slotId,
    ).equals('teacher1_20260110T0700Z');
  });

  test('maps lifecycle meeting_link_required', () {
    final failure = mapQuranSessionsCallableFailure(
      _callable(
        code: 'failed-precondition',
        message: 'Teacher has no external meeting URL configured.',
        details: const {'code': 'meeting_link_required', 'teacherId': 't1'},
      ),
      teacherId: 't1',
    );

    check(failure).isA<MeetingLinkUnavailableFailure>();
  });

  test('maps lifecycle teacher_not_verified', () {
    final failure = mapQuranSessionsCallableFailure(
      _callable(
        code: 'failed-precondition',
        details: const {
          'code': 'teacher_not_verified',
          'verificationStatus': 'pending',
        },
      ),
      teacherId: 'profile_1',
    );

    check(failure).isA<TeacherNotVerifiedFailure>();
    check((failure as TeacherNotVerifiedFailure).teacherId).equals('profile_1');
  });

  test(
    'maps already_active_on_other_device to LiveSessionAlreadyActiveFailure',
    () {
      final failure = mapQuranSessionsCallableFailure(
        _callable(
          code: 'already-exists',
          details: const {
            'code': 'already_active_on_other_device',
            'activeDeviceId': 'device_A',
            'sinceTs': 1700000000000,
            'activeIdentity': 'uid_1#device_A',
          },
        ),
        sessionId: 'session_42',
      );

      check(failure).isA<LiveSessionAlreadyActiveFailure>();
      final takeover = failure as LiveSessionAlreadyActiveFailure;
      check(takeover.sessionId).equals('session_42');
      check(takeover.activeDeviceId).equals('device_A');
      check(takeover.sinceMs).equals(1700000000000);
    },
  );

  test('maps lifecycle session_epoch_stale', () {
    final failure = mapQuranSessionsCallableFailure(
      _callable(
        code: 'failed-precondition',
        message: 'Session revoked on another device.',
        details: const {'code': 'session_epoch_stale'},
      ),
    );

    check(failure).isA<ServerFailure>();
    check((failure as ServerFailure).statusCode).equals(401);
  });

  test('maps legacy session epoch message without details code', () {
    final failure = mapQuranSessionsCallableFailure(
      _callable(
        code: 'failed-precondition',
        message: 'Session revoked on another device.',
      ),
    );

    check(failure).isA<ServerFailure>();
    check((failure as ServerFailure).statusCode).equals(401);
  });

  test('maps unavailable to network failure', () {
    final failure = mapQuranSessionsCallableFailure(
      _callable(code: 'unavailable', message: 'Service unavailable'),
    );

    check(failure).isA<NetworkFailure>();
  });

  test('maps internal to server failure', () {
    final failure = mapQuranSessionsCallableFailure(
      _callable(code: 'internal', message: 'Unhandled error'),
    );

    check(failure).isA<ServerFailure>();
    check((failure as ServerFailure).statusCode).equals(500);
  });

  test('maps lifecycle invalid_transition', () {
    final failure = mapQuranSessionsCallableFailure(
      _callable(
        code: 'failed-precondition',
        details: const {
          'code': 'invalid_transition',
          'action': 'confirm_free_booking',
        },
      ),
    );

    check(failure).isA<InvalidTransitionFailure>();
  });

  test('maps failed-precondition meeting URL message without details', () {
    final failure = mapQuranSessionsCallableFailure(
      _callable(
        code: 'failed-precondition',
        message: 'Teacher has no external meeting URL configured.',
      ),
    );

    check(failure).isA<MeetingLinkUnavailableFailure>();
  });

  test('maps profile_incomplete with missing fields', () {
    final failure = mapQuranSessionsCallableFailure(
      _callable(
        code: 'failed-precondition',
        details: const {
          'code': 'profile_incomplete',
          'missingFields': ['gender', 'cityId'],
        },
      ),
    );

    check(failure).isA<ProfileIncompleteFailure>();
    check(
      (failure as ProfileIncompleteFailure).missingFields,
    ).deepEquals(['gender', 'cityId']);
  });
}
