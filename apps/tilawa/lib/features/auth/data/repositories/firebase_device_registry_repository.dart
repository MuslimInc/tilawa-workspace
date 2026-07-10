import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/registered_device.dart';
import '../../domain/repositories/device_registry_repository.dart';
import '../services/device_identity_service.dart';

/// Firestore-backed [DeviceRegistryRepository]. Reads only
/// `users/{uid}/devices` with a single `get()` (no snapshot listener). The
/// stable device id is delegated to [DeviceIdentityService] so it matches the
/// id used during active-device registration.
@LazySingleton(as: DeviceRegistryRepository)
class FirebaseDeviceRegistryRepository implements DeviceRegistryRepository {
  FirebaseDeviceRegistryRepository(
    this._firestore,
    this._deviceIdentityService,
  );

  final FirebaseFirestore _firestore;
  final DeviceIdentityService _deviceIdentityService;

  @override
  Future<String> currentDeviceId() => _deviceIdentityService.getDeviceId();

  @override
  Future<Either<Failure, List<RegisteredDevice>>> getDevices(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .get();

      final devices = snapshot.docs.map(_mapDevice).toList()
        ..sort((a, b) {
          final aSeen = a.lastSeenAt;
          final bSeen = b.lastSeenAt;
          if (aSeen == null && bSeen == null) return 0;
          if (aSeen == null) return 1;
          if (bSeen == null) return -1;
          return bSeen.compareTo(aSeen);
        });
      return Right(devices);
    } on FirebaseException catch (error) {
      return Left(Failure.serverError(error.message ?? error.code));
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }

  RegisteredDevice _mapDevice(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final deviceInfo = data['deviceInfo'] as Map<String, dynamic>?;
    return RegisteredDevice(
      deviceId: doc.id,
      platform: data['platform'] as String? ?? 'unknown',
      appVersion: data['appVersion'] as String?,
      label: _label(deviceInfo),
      lastSeenAt: _dateTime(data['lastSeenAt']),
      createdAt: _dateTime(data['createdAt']),
      isRevoked: data['revokedAt'] != null,
    );
  }

  String? _label(Map<String, dynamic>? deviceInfo) {
    if (deviceInfo == null) return null;
    final manufacturer = (deviceInfo['manufacturer'] as String?)?.trim();
    final model = (deviceInfo['model'] as String?)?.trim();
    final parts = [
      if (manufacturer != null && manufacturer.isNotEmpty) manufacturer,
      if (model != null && model.isNotEmpty) model,
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

  DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
