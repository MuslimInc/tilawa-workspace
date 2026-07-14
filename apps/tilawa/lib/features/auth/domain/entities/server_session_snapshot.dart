/// Server-side session fields used for local-vs-remote validity checks.
class ServerSessionSnapshot {
  const ServerSessionSnapshot({
    required this.epoch,
    required this.activeDeviceId,
  });

  final int epoch;
  final String activeDeviceId;
}
