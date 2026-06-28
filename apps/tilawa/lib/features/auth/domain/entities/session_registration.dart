enum DeviceRegistrationMode {
  explicitSignIn('explicit_sign_in'),
  passiveSync('passive_sync');

  const DeviceRegistrationMode(this.wireName);

  final String wireName;
}

enum SessionRegistrationStatus {
  registered('registered'),
  updatedSameDevice('updated_same_device'),
  staleDeviceRejected('stale_device_rejected'),
  requiresExplicitSignIn('requires_explicit_sign_in');

  const SessionRegistrationStatus(this.wireName);

  final String wireName;

  static SessionRegistrationStatus fromWireName(String? value) {
    return SessionRegistrationStatus.values.firstWhere(
      (status) => status.wireName == value,
      orElse: () => SessionRegistrationStatus.registered,
    );
  }
}

/// Result of server-side active device registration.
class SessionRegistration {
  const SessionRegistration({
    required this.status,
    this.sessionEpoch,
    this.activeDeviceId,
  });

  final SessionRegistrationStatus status;
  final int? sessionEpoch;
  final String? activeDeviceId;

  int get epoch => sessionEpoch ?? 0;

  bool get isActiveDevice =>
      status == SessionRegistrationStatus.registered ||
      status == SessionRegistrationStatus.updatedSameDevice;
}
