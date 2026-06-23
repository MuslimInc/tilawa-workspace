import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

import 'agora_rtc_session_handle.dart';

/// Parameters for joining an Agora RTC channel.
class AgoraRtcJoinParams {
  const AgoraRtcJoinParams({
    required this.appId,
    required this.token,
    required this.channelId,
    required this.uid,
    required this.enableVideo,
  });

  final String appId;
  final String token;
  final String channelId;
  final int uid;
  final bool enableVideo;
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
    @visibleForTesting AgoraRtcEngineJoinRunner? joinRunner,
    @visibleForTesting AgoraRtcEngineReleaser? releaseEngine,
  }) : _joinRunner = joinRunner,
       _releaseEngine = releaseEngine ?? _defaultRelease;

  final AgoraRtcEngineJoinRunner? _joinRunner;
  final AgoraRtcEngineReleaser _releaseEngine;

  static Future<void> _defaultRelease(RtcEngine engine) => engine.release();

  @override
  Future<AgoraRtcSessionHandle> join(AgoraRtcJoinParams params) async {
    final engine = createAgoraRtcEngine();
    try {
      if (_joinRunner != null) {
        await _joinRunner(engine, params);
      } else {
        await _joinLive(engine, params);
      }
      return LiveAgoraRtcSessionHandle(engine);
    } on Object {
      await _releaseEngine(engine);
      rethrow;
    }
  }

  Future<void> _joinLive(RtcEngine engine, AgoraRtcJoinParams params) async {
    await engine.initialize(
      RtcEngineContext(
        appId: params.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

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
  }
}
