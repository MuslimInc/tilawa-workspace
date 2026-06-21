/// Typed exceptions that remote datasource implementations throw.
///
/// Repository implementations catch these and map them to the corresponding
/// [QuranSessionsFailure] subtype. No exception crosses the repository
/// boundary — callers always receive [Either<QuranSessionsFailure, T>].
sealed class RemoteException implements Exception {
  const RemoteException();
}

/// No network connectivity or DNS failure.
final class NetworkException extends RemoteException {
  const NetworkException();
}

/// The request did not complete within the allowed time.
final class TimeoutException extends RemoteException {
  const TimeoutException();
}

/// The server responded with an HTTP error status.
final class HttpException extends RemoteException {
  const HttpException(this.statusCode, {this.body});
  final int statusCode;
  final String? body;
}

/// The resource was not found (HTTP 404 or equivalent).
final class NotFoundException extends RemoteException {
  const NotFoundException(this.resourceType);
  final String resourceType;
}

/// A booking could not be created due to a domain conflict (e.g. slot taken).
final class ConflictException extends RemoteException {
  const ConflictException({this.isSlotUnavailable = false, this.slotId});
  final bool isSlotUnavailable;
  final String? slotId;
}

/// Caller lacks permission for the requested resource.
final class PermissionDeniedException extends RemoteException {
  const PermissionDeniedException();
}

/// Backend rejected the payload (HTTP 400 or equivalent).
final class ValidationRemoteException extends RemoteException {
  const ValidationRemoteException({required this.field, required this.code});
  final String field;
  final String code;
}
