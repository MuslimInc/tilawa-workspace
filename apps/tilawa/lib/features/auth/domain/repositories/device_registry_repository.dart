import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/registered_device.dart';

/// Read access to the non-exclusive device registry (ADR-008 Phase 0).
///
/// Reads are **fetch-on-open** (a single `get`, never a live listener) to keep
/// Firebase cost predictable — see the Manage Devices plan (§9). Writes are
/// Cloud-Functions-only and never exposed here.
abstract class DeviceRegistryRepository {
  /// The stable per-install device id used when registering this device. Same
  /// source as active-device registration so the caller can flag "this device".
  Future<String> currentDeviceId();

  /// One-shot read of the caller's registered devices, most recently seen
  /// first. Returns a [Failure] on read error; never throws across the boundary.
  Future<Either<Failure, List<RegisteredDevice>>> getDevices(String userId);

  /// Signs out one device the caller owns (server sets `revokedAt`; the device
  /// discovers it on next resume / `device_revoked` push). Cloud-Functions-only
  /// write. Idempotent.
  Future<Either<Failure, void>> revokeDevice(String deviceId);

  /// Signs out every device the caller owns *except* [currentDeviceId]. Never
  /// affects the current device's session (no Firebase refresh-token revoke).
  Future<Either<Failure, void>> signOutOtherDevices(String currentDeviceId);
}
