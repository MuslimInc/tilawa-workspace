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
}
