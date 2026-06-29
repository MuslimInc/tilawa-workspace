import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firebase_callable_failure_mapper.dart';
import 'package:tilawa/features/quran_sessions/debug/quran_sessions_debug_tools.dart';

/// Fetches short-lived Agora RTC tokens from [issueSessionRtcToken] CF.
class FirebaseCallTokenProvider implements CallTokenProvider {
  FirebaseCallTokenProvider(
    this._payloadBuilder, {
    this._functions,
    @visibleForTesting this._issueSessionRtcTokenInvoker,
  });

  final FirebaseFunctions? _functions;
  final CallableSessionPayloadBuilder _payloadBuilder;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)?
  _issueSessionRtcTokenInvoker;

  @override
  Future<RtcJoinCredentials> fetchCredentials({
    required String sessionId,
    required String userId,
  }) async {
    final isDebugLiveKitJoin = sessionId == kDebugLiveKitSessionId;
    final callableName = isDebugLiveKitJoin
        ? 'issueDebugLiveKitToken'
        : 'issueSessionRtcToken';
    final payload = isDebugLiveKitJoin
        ? <String, dynamic>{}
        : await _payloadBuilder.withSessionEpoch({
            'sessionId': sessionId,
          });
    final Map<String, dynamic> data;
    final invoker = _issueSessionRtcTokenInvoker;
    try {
      if (invoker != null) {
        data = await invoker(payload);
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
      throw mapQuranSessionsCallableFailure(error);
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
}
