import 'package:equatable/equatable.dart';

/// Typed failures for the call-tracking business domain.
///
/// The domain never throws across boundaries — every fallible operation
/// returns `Either<CallTrackingFailure, T>` (dartz_plus). These failures are
/// raised at the *parse boundary* (turning untrusted client/provider payloads
/// into validated domain events) and never from the pure calculator, which is
/// total once it receives well-formed events.
sealed class CallTrackingFailure extends Equatable {
  const CallTrackingFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => '$runtimeType($message)';
}

/// An event arrived without a usable timestamp (null or non-positive epoch).
final class MissingTimestampFailure extends CallTrackingFailure {
  const MissingTimestampFailure([
    super.message = 'Call event is missing a valid timestamp.',
  ]);
}

/// An event referenced a participant role outside {teacher, student}.
final class InvalidParticipantRoleFailure extends CallTrackingFailure {
  const InvalidParticipantRoleFailure(this.rawRole)
    : super('Unknown participant role: "$rawRole".');

  final String rawRole;

  @override
  List<Object?> get props => [message, rawRole];
}

/// An event referenced an unknown lifecycle type.
final class InvalidEventTypeFailure extends CallTrackingFailure {
  const InvalidEventTypeFailure(this.rawType)
    : super('Unknown call event type: "$rawType".');

  final String rawType;

  @override
  List<Object?> get props => [message, rawType];
}
