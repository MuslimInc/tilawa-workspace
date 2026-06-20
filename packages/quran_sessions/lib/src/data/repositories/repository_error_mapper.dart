import '../../domain/failures/quran_sessions_failure.dart';
import '../exceptions/remote_exception.dart';

/// Maps any [RemoteException] (or unknown [Exception]) to the canonical
/// [QuranSessionsFailure] subtype.
///
/// Call this inside every repository `on Exception catch` handler:
/// ```dart
/// } on Exception catch (e) {
///   return Left(mapRemoteException(e));
/// }
/// ```
QuranSessionsFailure mapRemoteException(Exception e) => switch (e) {
  NetworkException() => const NetworkFailure(),
  TimeoutException() => const TimeoutFailure(),
  NotFoundException(:final resourceType) => NotFoundFailure(resourceType),
  ConflictException(isSlotUnavailable: true, :final slotId) =>
    SlotUnavailableFailure(slotId ?? ''),
  ConflictException() => const BookingConflictFailure(),
  HttpException(:final statusCode) when statusCode == 401 =>
    const UnauthorizedFailure(),
  HttpException(:final statusCode) when statusCode == 403 =>
    const UnauthorizedFailure(),
  HttpException(:final statusCode) => ServerFailure(statusCode: statusCode),
  _ => const UnknownFailure(),
};
