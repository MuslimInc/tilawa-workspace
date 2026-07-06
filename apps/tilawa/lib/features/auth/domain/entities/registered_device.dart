import 'package:equatable/equatable.dart';

/// A single entry from the non-exclusive device registry
/// (`users/{uid}/devices/{deviceId}`) introduced in ADR-008 Phase 0.
///
/// Pure domain value object — no Firebase types. Read-only on the client; the
/// registry is written exclusively by Cloud Functions.
class RegisteredDevice extends Equatable {
  const RegisteredDevice({
    required this.deviceId,
    required this.platform,
    this.appVersion,
    this.label,
    this.lastSeenAt,
    this.createdAt,
    this.isRevoked = false,
  });

  /// Firestore document id — the stable per-install device id.
  final String deviceId;

  /// `android` | `ios` | `web`.
  final String platform;

  final String? appVersion;

  /// Human-readable label, e.g. `Samsung Galaxy S23`, derived from the
  /// sanitized `deviceInfo` (manufacturer + model) when present.
  final String? label;

  final DateTime? lastSeenAt;
  final DateTime? createdAt;

  /// Whether this device has been signed out via a Manage Devices action.
  final bool isRevoked;

  @override
  List<Object?> get props => [
    deviceId,
    platform,
    appVersion,
    label,
    lastSeenAt,
    createdAt,
    isRevoked,
  ];
}
