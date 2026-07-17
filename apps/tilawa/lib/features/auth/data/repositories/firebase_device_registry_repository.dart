import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/registered_device.dart';
import '../../domain/repositories/device_registry_repository.dart';
import '../services/device_identity_service.dart';

/// Firestore-backed [DeviceRegistryRepository]. Reads only
/// `users/{uid}/devices` with a single `get()` (no snapshot listener). The
/// stable device id is delegated to [DeviceIdentityService] so it matches the
/// id used during active-device registration. Management writes go through the
/// `revokeDevice` / `signOutOtherDevices` Cloud Functions (registry docs are
/// never client-writable).
@LazySingleton(as: DeviceRegistryRepository)
class FirebaseDeviceRegistryRepository implements DeviceRegistryRepository {
  FirebaseDeviceRegistryRepository(
    this._firestore,
    this._deviceIdentityService,
    this._functions,
    this._auth,
  );

  final FirebaseFirestore _firestore;
  final DeviceIdentityService _deviceIdentityService;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  /// Cold-start AuthBloc can emit [AuthAuthenticated] from a persisted hint
  /// while [FirebaseAuth.currentUser] is still null
  /// ([AuthRestorationOutcome.pendingUnresolved]). Firestore then sees
  /// `request.auth == null` and returns PERMISSION_DENIED on
  /// `users/{uid}/devices`. Wait briefly for the live session before reading.
  static const Duration _authReadyTimeout = Duration(seconds: 5);

  @override
  Future<String> currentDeviceId() => _deviceIdentityService.getDeviceId();

  @override
  Future<Either<Failure, void>> revokeDevice(String deviceId) async {
    return _callManagement(
      'revokeDevice',
      <String, dynamic>{'deviceId': deviceId},
    );
  }

  @override
  Future<Either<Failure, void>> signOutOtherDevices(
    String currentDeviceId,
  ) async {
    return _callManagement(
      'signOutOtherDevices',
      <String, dynamic>{'currentDeviceId': currentDeviceId},
    );
  }

  Future<Either<Failure, void>> _callManagement(
    String name,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _functions.httpsCallable(name).call<Map<String, dynamic>>(payload);
      return const Right(null);
    } on FirebaseFunctionsException catch (error) {
      return Left(Failure.serverError(error.message ?? error.code));
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RegisteredDevice>>> getDevices(
    String userId,
  ) async {
    try {
      final User? authUser = await _waitForAuthUser();
      if (authUser == null) {
        return Left(Failure.serverError('unauthenticated'));
      }

      // Always query the live Auth uid — never a stale AuthBloc hint.
      final String uid = authUser.uid;
      if (userId.isNotEmpty && userId != uid) {
        return Left(Failure.serverError('permission-denied'));
      }
      await authUser.getIdToken();

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
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
    } on PlatformException catch (error) {
      return Left(
        Failure.serverError(error.message ?? error.code),
      );
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }

  /// Returns the live Firebase user, waiting briefly if Auth is still
  /// restoring a persisted session after cold start.
  Future<User?> _waitForAuthUser() async {
    final User? existing = _auth.currentUser;
    if (existing != null) {
      return existing;
    }
    try {
      await _auth
          .authStateChanges()
          .where((User? user) => user != null)
          .first
          .timeout(_authReadyTimeout);
    } on TimeoutException {
      // Fall through — return whatever Auth has now (likely still null).
    } on Object {
      // Stream closed / cancelled before a user appeared.
    }
    return _auth.currentUser;
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
