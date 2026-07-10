import 'package:checks/checks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/data/services/device_identity_service.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';
import 'package:tilawa/features/auth/domain/services/session_epoch_provider.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firebase_call_token_provider.dart';
import 'package:tilawa/features/quran_sessions/debug/quran_sessions_debug_tools.dart';

class _FakePayloadBuilder extends CallableSessionPayloadBuilder {
  _FakePayloadBuilder() : super(_FakeEpochProvider());
}

class _FakeEpochProvider implements SessionEpochProvider {
  @override
  Future<int> getSessionEpoch() async => 7;
}

class _FakeDeviceIdentity implements DeviceIdentityService {
  @override
  Future<String> getDeviceId() async => 'device_test';

  @override
  String get platform => 'android';
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

FirebaseCallTokenProvider _provider({
  required Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)
  invoke,
  DeviceIdentityService? deviceIdentity,
}) {
  return FirebaseCallTokenProvider(
    _FakePayloadBuilder(),
    deviceIdentity ?? _FakeDeviceIdentity(),
    issueSessionRtcTokenInvoker: invoke,
  );
}

void main() {
  group('FirebaseCallTokenProvider', () {
    test('maps valid callable payload to RtcJoinCredentials', () async {
      final provider = _provider(
        invoke: (payload) async {
          check(payload['sessionId']).equals('session_1');
          check(payload['sessionEpoch']).equals(7);
          check(payload['deviceId']).equals('device_test');
          check(payload['forceTakeover']).equals(false);
          return {
            'token': ' rtc-token ',
            'channelId': ' channel-1 ',
            'uid': 918273,
            'appId': ' app-id ',
          };
        },
      );

      final credentials = await provider.fetchCredentials(
        sessionId: 'session_1',
        userId: 'user_1',
      );

      check(credentials.token).equals('rtc-token');
      check(credentials.channelId).equals('channel-1');
      check(credentials.uid).equals(918273);
      check(credentials.appId).equals('app-id');
    });

    test('forwards forceTakeover=true in the callable payload', () async {
      final provider = _provider(
        invoke: (payload) async {
          check(payload['forceTakeover']).equals(true);
          return {
            'token': 'rtc-token',
            'channelId': 'channel-1',
            'uid': 1,
            'appId': 'app-id',
          };
        },
      );

      final credentials = await provider.fetchCredentials(
        sessionId: 'session_1',
        userId: 'user_1',
        forceTakeover: true,
      );

      check(credentials.token).equals('rtc-token');
    });

    test('debug LiveKit join uses empty payload', () async {
      Map<String, dynamic>? capturedPayload;
      final provider = _provider(
        invoke: (payload) async {
          capturedPayload = payload;
          return {
            'token': 'livekit-token',
            'channelId': kDebugLiveKitRoomName,
            'uid': 0,
            'appId': 'wss://tilawa-7whzug8z.livekit.cloud',
          };
        },
      );

      final credentials = await provider.fetchCredentials(
        sessionId: kDebugLiveKitSessionId,
        userId: 'user_1',
      );

      check(capturedPayload).isNotNull();
      check(capturedPayload!).isEmpty();
      check(credentials.channelId).equals(kDebugLiveKitRoomName);
    });

    test(
      'debug LiveKit join fails when Firebase Auth user is missing',
      () async {
        final auth = _MockFirebaseAuth();
        when(() => auth.currentUser).thenReturn(null);
        final provider = FirebaseCallTokenProvider(
          _FakePayloadBuilder(),
          _FakeDeviceIdentity(),
          auth: auth,
        );

        await expectLater(
          provider.fetchCredentials(
            sessionId: kDebugLiveKitSessionId,
            userId: 'user_1',
          ),
          throwsA(
            isA<RtcCallJoinFailure>().having(
              (failure) => failure.reasonCode,
              'reasonCode',
              'debug_callable_unauthorized',
            ),
          ),
        );
      },
    );

    test(
      'debug LiveKit join is blocked when callable guard rejects build',
      () async {
        final provider = FirebaseCallTokenProvider(
          _FakePayloadBuilder(),
          _FakeDeviceIdentity(),
          debugLiveKitCallableAllowed: () => false,
          issueSessionRtcTokenInvoker: (_) async => {
            'token': 'livekit-token',
            'channelId': kDebugLiveKitRoomName,
            'uid': 0,
            'appId': 'wss://tilawa-7whzug8z.livekit.cloud',
          },
        );

        await expectLater(
          provider.fetchCredentials(
            sessionId: kDebugLiveKitSessionId,
            userId: 'user_1',
          ),
          throwsA(
            isA<RtcCallJoinFailure>().having(
              (failure) => failure.reasonCode,
              'reasonCode',
              'debug_callable_unauthorized',
            ),
          ),
        );
      },
    );

    test('rejects missing or blank token', () async {
      final provider = _provider(
        invoke: (_) async => {
          'token': ' ',
          'channelId': 'channel-1',
          'uid': 1,
          'appId': 'app-id',
        },
      );

      await expectLater(
        provider.fetchCredentials(sessionId: 's1', userId: 'u1'),
        throwsA(
          isA<RtcCallJoinFailure>().having(
            (failure) => failure.reasonCode,
            'reasonCode',
            'invalid_token_response',
          ),
        ),
      );
    });

    test('rejects missing or blank channel id', () async {
      final provider = _provider(
        invoke: (_) async => {
          'token': 'token',
          'channelId': '',
          'uid': 1,
          'appId': 'app-id',
        },
      );

      await expectLater(
        provider.fetchCredentials(sessionId: 's1', userId: 'u1'),
        throwsA(
          isA<RtcCallJoinFailure>().having(
            (failure) => failure.reasonCode,
            'reasonCode',
            'invalid_channel_response',
          ),
        ),
      );
    });

    test('rejects non-numeric uid', () async {
      final provider = _provider(
        invoke: (_) async => {
          'token': 'token',
          'channelId': 'channel-1',
          'uid': 'not-a-number',
          'appId': 'app-id',
        },
      );

      await expectLater(
        provider.fetchCredentials(sessionId: 's1', userId: 'u1'),
        throwsA(
          isA<RtcCallJoinFailure>().having(
            (failure) => failure.reasonCode,
            'reasonCode',
            'invalid_uid_response',
          ),
        ),
      );
    });

    test('rejects missing or blank app id', () async {
      final provider = _provider(
        invoke: (_) async => {
          'token': 'token',
          'channelId': 'channel-1',
          'uid': 1,
          'appId': '',
        },
      );

      await expectLater(
        provider.fetchCredentials(sessionId: 's1', userId: 'u1'),
        throwsA(
          isA<RtcCallJoinFailure>().having(
            (failure) => failure.reasonCode,
            'reasonCode',
            'invalid_app_id_response',
          ),
        ),
      );
    });
  });
}
