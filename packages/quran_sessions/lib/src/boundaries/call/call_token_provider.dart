/// Fetches short-lived tokens required to join a call room.
///
/// For Agora this means an RTC token; for WebRTC a TURN credential.
/// The backend issues tokens — this package never calls Agora or TURN servers
/// directly.
abstract interface class CallTokenProvider {
  Future<String> fetchToken({
    required String sessionId,
    required String userId,
  });
}
