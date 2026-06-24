/// Server-issued RTC join payload from [issueSessionRtcToken].
///
/// The client must use [uid], [channelId], and [token] verbatim — never derive
/// Agora uids locally.
class RtcJoinCredentials {
  const RtcJoinCredentials({
    required this.token,
    required this.channelId,
    required this.uid,
    required this.appId,
  });

  final String token;
  final String channelId;
  final int uid;
  final String appId;
}
