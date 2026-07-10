import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/data/services/device_identity_service.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firebase_callable_failure_mapper.dart';
import 'package:tilawa/features/quran_sessions/debug/quran_sessions_debug_tools.dart';

/// Fetches short-lived Agora RTC tokens from [issueSessionRtcToken] CF.
class FirebaseCallTokenProvider implements CallTokenProvider {
  FirebaseCallTokenProvider(
    this._payloadBuilder,
    this._deviceIdentityService, {
    this._functions,
    FirebaseAuth? auth,
    @visibleForTesting this._issueSessionRtcTokenInvoker,
    @visibleForTesting this._debugLiveKitCallableAllowed,
  }) : _authOverride = auth;

  final FirebaseFunctions? _functions;
  final FirebaseAuth? _authOverride;
  final CallableSessionPayloadBuilder _payloadBuilder;
  final DeviceIdentityService _deviceIdentityService;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)?
  _issueSessionRtcTokenInvoker;
  final bool Function()? _debugLiveKitCallableAllowed;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  @override
  Future<RtcJoinCredentials> fetchCredentials({
    required String sessionId,
    required String userId,
    bool forceTakeover = false,
  }) async {
    final isDebugLiveKitJoin = sessionId == kDebugLiveKitSessionId;
    if (isDebugLiveKitJoin &&
        !(_debugLiveKitCallableAllowed?.call() ??
            isDebugLiveKitCallableAllowed())) {
      throw const RtcCallJoinFailure(reasonCode: 'debug_callable_unauthorized');
    }
    final callableName = isDebugLiveKitJoin
        ? 'issueDebugLiveKitToken'
        : 'issueSessionRtcToken';
    // ADR-008 Phase 2: the stable device id keys the per-session live lock;
    // forceTakeover is the user-initiated "Switch to this device" intent. Both
    // are ignored by the server when the live-lock flag is off, so legacy
    // behavior is unchanged. The debug LiveKit path sends an empty payload.
    final payload = isDebugLiveKitJoin
        ? <String, dynamic>{}
        : await _payloadBuilder.withSessionEpoch({
            'sessionId': sessionId,
            'deviceId': await _deviceIdentityService.getDeviceId(),
            'forceTakeover': forceTakeover,
          });
    final Map<String, dynamic> data;
    final invoker = _issueSessionRtcTokenInvoker;
    try {
      if (invoker != null) {
        data = await invoker(payload);
      } else if (isDebugLiveKitJoin) {
        await _ensureDebugCallableAuthAttached();
        data = await _invokeDebugLiveKitCallable(payload);
      } else {
        final functions = _functions;
        if (functions == null) {
          throw StateError(
            'FirebaseCallTokenProvider requires FirebaseFunctions when '
            'issueSessionRtcTokenInvoker is unset.',
          );
        }
        data =
            (await functions
                    .httpsCallable(callableName)
                    .call<Map<String, dynamic>>(payload))
                .data;
      }
    } on FirebaseFunctionsException catch (error) {
      if (isDebugLiveKitJoin) {
        throw mapDebugLiveKitTokenCallableFailure(error);
      }
      throw mapQuranSessionsCallableFailure(error, sessionId: sessionId);
    }

    final token = data['token'];
    final channelId = data['channelId'];
    final uid = data['uid'];
    final appId = data['appId'];

    if (token is! String || token.trim().isEmpty) {
      throw const RtcCallJoinFailure(reasonCode: 'invalid_token_response');
    }
    if (channelId is! String || channelId.trim().isEmpty) {
      throw const RtcCallJoinFailure(reasonCode: 'invalid_channel_response');
    }
    if (uid is! num) {
      throw const RtcCallJoinFailure(reasonCode: 'invalid_uid_response');
    }
    if (appId is! String || appId.trim().isEmpty) {
      throw const RtcCallJoinFailure(reasonCode: 'invalid_app_id_response');
    }

    return RtcJoinCredentials(
      token: token.trim(),
      channelId: channelId.trim(),
      uid: uid.toInt(),
      appId: appId.trim(),
    );
  }

  Future<void> _ensureDebugCallableAuthAttached() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const RtcCallJoinFailure(reasonCode: 'debug_callable_unauthorized');
    }
    await user.getIdToken(true);
  }

  Future<Map<String, dynamic>> _invokeDebugLiveKitCallable(
    Map<String, dynamic> payload,
  ) async {
    final functions = _functions;
    if (functions == null) {
      throw StateError(
        'FirebaseCallTokenProvider requires FirebaseFunctions when '
        'issueSessionRtcTokenInvoker is unset.',
      );
    }
    return (await functions
            .httpsCallable('issueDebugLiveKitToken')
            .call<Map<String, dynamic>>(payload))
        .data;
  }
}
