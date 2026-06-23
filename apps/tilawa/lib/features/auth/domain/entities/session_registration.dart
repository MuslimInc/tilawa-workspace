/// Result of server-side active device registration.
class SessionRegistration {
  const SessionRegistration({
    required this.epoch,
    required this.activeDeviceId,
  });

  final int epoch;
  final String activeDeviceId;
}
