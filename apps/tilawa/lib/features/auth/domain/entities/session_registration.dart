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
    this.deviceCapExceeded,
    this.registeredDeviceCount,
  });

  final SessionRegistrationStatus status;
  final int? sessionEpoch;
  final String? activeDeviceId;

  /// ADR-008 Phase 0 — set only when the device registry write was requested.
  /// `true` means the user is at/over the 5-device soft cap; never blocking.
  final bool? deviceCapExceeded;

  /// Number of registered (non-revoked) devices after this registration, when
  /// the registry write was requested.
  final int? registeredDeviceCount;

  int get epoch => sessionEpoch ?? 0;

  bool get isActiveDevice =>
      status == SessionRegistrationStatus.registered ||
      status == SessionRegistrationStatus.updatedSameDevice;
}
