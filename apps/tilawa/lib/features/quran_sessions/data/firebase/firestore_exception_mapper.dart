import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// Maps [FirebaseException] codes to backend-agnostic [RemoteException]s.
///
/// Firebase types must never cross the repository boundary.
Exception mapFirebaseException(FirebaseException exception) {
  return switch (exception.code) {
    'permission-denied' => const PermissionDeniedException(),
    'unauthenticated' => const HttpException(401),
    'unavailable' => const NetworkException(),
    'deadline-exceeded' => const TimeoutException(),
    'not-found' => NotFoundException(exception.message ?? 'resource'),
    'already-exists' || 'aborted' => const ConflictException(),
    'invalid-argument' => const ValidationRemoteException(
      field: 'request',
      code: 'invalid',
    ),
    _ => HttpException(500, body: exception.message),
  };
}

/// Reads a Firestore timestamp or ISO string as [DateTime].
DateTime? readDateTime(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

DateTime readRequiredDateTime(Object? value, {DateTime? fallback}) =>
    readDateTime(value) ?? fallback ?? DateTime.now();

/// Writes [DateTime] for Firestore (server-side timestamps use [FieldValue]).
Object writeDateTime(DateTime value) => Timestamp.fromDate(value.toUtc());

Object? writeOptionalDateTime(DateTime? value) =>
    value == null ? null : writeDateTime(value);
