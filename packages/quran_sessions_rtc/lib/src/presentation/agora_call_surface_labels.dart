/// User-visible strings for [AgoraCallSurface] — supplied by host app l10n.
class AgoraCallSurfaceLabels {
  const AgoraCallSurfaceLabels({
    required this.connecting,
    required this.connected,
    required this.waitingForParticipant,
    required this.voiceCallTitle,
  });

  final String connecting;
  final String connected;
  final String waitingForParticipant;
  final String voiceCallTitle;
}
