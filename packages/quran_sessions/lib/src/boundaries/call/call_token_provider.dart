import '../../domain/entities/rtc_join_credentials.dart';

/// Fetches short-lived tokens required to join a call room.
///
/// For Agora this means an RTC token; for LiveKit a room JWT.
/// The backend issues tokens — this package never calls Agora or TURN servers
/// directly.
abstract interface class CallTokenProvider {
  Future<RtcJoinCredentials> fetchCredentials({
    required String sessionId,
    required String userId,
  });
}
