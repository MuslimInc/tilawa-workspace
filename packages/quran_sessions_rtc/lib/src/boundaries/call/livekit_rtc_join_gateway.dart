import 'package:livekit_client/livekit_client.dart';

import 'livekit_rtc_session_handle.dart';

class LiveKitJoinParams {
  const LiveKitJoinParams({
    required this.serverUrl,
    required this.token,
    required this.enableVideo,
  });

  final String serverUrl;
  final String token;
  final bool enableVideo;
}

abstract class LiveKitRtcJoinGateway {
  Future<LiveKitRtcSessionHandle> join(LiveKitJoinParams params);
}

class LiveLiveKitRtcJoinGateway implements LiveKitRtcJoinGateway {
  @override
  Future<LiveKitRtcSessionHandle> join(LiveKitJoinParams params) async {
    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );
    await room.connect(params.serverUrl, params.token);
    await room.localParticipant?.setMicrophoneEnabled(true);
    if (params.enableVideo) {
      try {
        await room.localParticipant?.setCameraEnabled(true);
      } on Object {
        // Video may fail on simulators; voice-only join still succeeds.
      }
    }
    return LiveLiveKitRtcSessionHandle(room);
  }
}
