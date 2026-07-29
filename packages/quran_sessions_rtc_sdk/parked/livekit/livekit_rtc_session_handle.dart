import 'package:livekit_client/livekit_client.dart';

/// Active LiveKit session resources released on leave/end.
abstract class LiveKitRtcSessionHandle {
  Future<void> leaveAndRelease();

  Future<void> setMicrophoneMuted(bool muted);

  Future<void> setCameraEnabled(bool enabled);

  Future<void> switchCamera();

  Future<void> setSpeakerEnabled(bool enabled);

  /// Native room for in-call video rendering; null in test fakes.
  Room? get room;
}

/// Production handle wrapping a native [Room].
class LiveLiveKitRtcSessionHandle implements LiveKitRtcSessionHandle {
  LiveLiveKitRtcSessionHandle(this._room);

  final Room _room;

  @override
  Room get room => _room;

  @override
  Future<void> leaveAndRelease() async {
    await _room.disconnect();
    await _room.dispose();
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {
    await _room.localParticipant?.setMicrophoneEnabled(!muted);
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    await _room.localParticipant?.setCameraEnabled(enabled);
  }

  @override
  Future<void> switchCamera() async {
    final participant = _room.localParticipant;
    if (participant == null) {
      return;
    }
    for (final pub in participant.videoTrackPublications) {
      if (pub.isScreenShare) {
        continue;
      }
      final track = pub.track;
      if (track is LocalVideoTrack) {
        final options = track.currentOptions;
        if (options is CameraCaptureOptions) {
          await track.setCameraPosition(options.cameraPosition.switched());
        }
        return;
      }
    }
  }

  @override
  Future<void> setSpeakerEnabled(bool enabled) async {
    await AudioManager.instance.setSpeakerOutputPreferred(enabled);
  }
}
