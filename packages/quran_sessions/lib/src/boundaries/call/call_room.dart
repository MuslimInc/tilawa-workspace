/// Represents an active call room returned by [CallProvider.joinSession].
///
/// The concrete shape depends on the provider:
/// - [ExternalMeetingCallProvider] → [meetingUrl] is populated, rest null.
/// - Agora / WebRTC → [channelId] and [token] are populated.
class CallRoom {
  const CallRoom({
    required this.sessionId,
    this.meetingUrl,
    this.channelId,
    this.token,
    this.extraData,
  });

  final String sessionId;

  /// For [ExternalMeetingCallProvider]: the URL to open in the browser/app.
  final String? meetingUrl;

  /// For Agora / WebRTC: the channel / room identifier.
  final String? channelId;

  /// For Agora / WebRTC: the short-lived call token.
  final String? token;

  /// Provider-specific extra fields; kept as an opaque map so this class
  /// never needs to know about SDK-specific types.
  final Map<String, dynamic>? extraData;
}
