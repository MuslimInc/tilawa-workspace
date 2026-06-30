import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'agora_rtc_session_handle.dart';

/// Parameters for joining an Agora RTC channel.
class AgoraRtcJoinParams {
  const AgoraRtcJoinParams({
    required this.appId,
    required this.token,
    required this.channelId,
    required this.uid,
    required this.enableVideo,
    this.existingEngine,
  });

  final String appId;
  final String token;
  final String channelId;
  final int uid;
  final bool enableVideo;

  /// Reuse a parked engine from [AgoraRtcEnginePool] when [appId] matches.
  final RtcEngine? existingEngine;
}

/// Joins an Agora channel and returns a releasable session handle.
abstract class AgoraRtcJoinGateway {
  Future<AgoraRtcSessionHandle> join(AgoraRtcJoinParams params);
}

typedef AgoraRtcEngineJoinRunner =
    Future<void> Function(RtcEngine engine, AgoraRtcJoinParams params);

typedef AgoraRtcEngineReleaser = Future<void> Function(RtcEngine engine);

/// Native Agora join via [RtcEngine].
class LiveAgoraRtcJoinGateway implements AgoraRtcJoinGateway {
  LiveAgoraRtcJoinGateway({
    @visibleForTesting this._joinRunner,
    @visibleForTesting AgoraRtcEngineReleaser? releaseEngine,
  }) : _releaseEngine = releaseEngine ?? _defaultRelease;

  final AgoraRtcEngineJoinRunner? _joinRunner;
  final AgoraRtcEngineReleaser _releaseEngine;

  static Future<void> _defaultRelease(RtcEngine engine) => engine.release();

  @override
  Future<AgoraRtcSessionHandle> join(AgoraRtcJoinParams params) async {
    final engine = params.existingEngine ?? createAgoraRtcEngine();
    final ownsEngine = params.existingEngine == null;
    try {
      if (_joinRunner != null) {
        await _joinRunner(engine, params);
      } else {
        await _joinLive(engine, params, skipInitialize: !ownsEngine);
      }
      return LiveAgoraRtcSessionHandle(engine, appId: params.appId);
    } on RtcCallJoinFailure {
      if (ownsEngine) {
        await _releaseEngine(engine);
      }
      rethrow;
    } on Object catch (error) {
      if (ownsEngine) {
        await _releaseEngine(engine);
      }
      throw mapAgoraRtcJoinFailure(error);
    }
  }

  Future<void> _joinLive(
    RtcEngine engine,
    AgoraRtcJoinParams params, {
    bool skipInitialize = false,
  }) async {
    // coverage:ignore-start
    if (!skipInitialize) {
      await engine.initialize(
        RtcEngineContext(
          appId: params.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    }

    await engine.enableAudio();
    if (params.enableVideo) {
      await engine.enableVideo();
    }

    await engine.joinChannel(
      token: params.token,
      channelId: params.channelId,
      uid: params.uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    // coverage:ignore-end
  }
}

/// Maps native Agora join errors to domain [RtcCallJoinFailure] reason codes.
@visibleForTesting
RtcCallJoinFailure mapAgoraRtcJoinFailure(Object error) {
  if (error is RtcCallJoinFailure) {
    return error;
  }
  if (error is AgoraRtcException) {
    final reasonCode = switch (error.code) {
      -17 => 'join_channel_rejected',
      -2 => 'join_invalid_argument',
      -7 => 'join_not_initialized',
      -102 => 'join_invalid_token',
      -109 => 'join_token_expired',
      _ => 'join_failed',
    };
    return RtcCallJoinFailure(reasonCode: reasonCode);
  }
  return const RtcCallJoinFailure(reasonCode: 'join_failed');
}
