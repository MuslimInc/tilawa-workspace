import 'package:equatable/equatable.dart';

/// Typed failure hierarchy for the quran_sessions package.
///
/// Every failure subtype carries structured data — never a pre-translated
/// string. The host app provides a mapper/extension that converts these to
/// the correct localised message:
///
/// ```dart
/// // In the host app (NOT in this package):
/// extension QuranSessionsFailureL10n on QuranSessionsFailure {
///   String toLocalizedMessage(BuildContext context) => switch (this) {
///     NetworkFailure()      => context.l10n.errorNetwork,
///     ServerFailure(statusCode: 401) => context.l10n.errorUnauthorized,
///     ServerFailure()       => context.l10n.errorServer,
///     NotFoundFailure()     => context.l10n.errorNotFound,
///     UnauthorizedFailure() => context.l10n.errorUnauthorized,
///     CacheFailure()        => context.l10n.errorCache,
///     UnknownFailure()      => context.l10n.errorUnknown,
///     ValidationFailure(:final field) => context.l10n.errorValidation(field),
///     BookingConflictFailure() => context.l10n.errorBookingConflict,
///     SlotUnavailableFailure() => context.l10n.errorSlotUnavailable,
///   };
/// }
/// ```
///
/// The UI then calls `state.failure.toLocalizedMessage(context)`.
/// Neither BLoC states, BLoCs, nor repositories ever produce a localised String.
sealed class QuranSessionsFailure extends Equatable {
  const QuranSessionsFailure();

  @override
  List<Object?> get props => [];
}

// ── Network / transport ───────────────────────────────────────────────────────

final class NetworkFailure extends QuranSessionsFailure {
  const NetworkFailure();
}

final class TimeoutFailure extends QuranSessionsFailure {
  const TimeoutFailure();
}

// ── Server / HTTP ─────────────────────────────────────────────────────────────

final class ServerFailure extends QuranSessionsFailure {
  const ServerFailure({required this.statusCode});

  final int statusCode;

  @override
  List<Object?> get props => [statusCode];
}

final class UnauthorizedFailure extends QuranSessionsFailure {
  const UnauthorizedFailure();
}

// ── Domain / resource ─────────────────────────────────────────────────────────

final class NotFoundFailure extends QuranSessionsFailure {
  const NotFoundFailure(this.resourceType);

  final String resourceType;

  @override
  List<Object?> get props => [resourceType];
}

final class ValidationFailure extends QuranSessionsFailure {
  const ValidationFailure({required this.field, required this.code});

  /// The field name that failed (e.g. 'slotId', 'rating').
  final String field;

  /// Machine-readable validation code (e.g. 'required', 'out_of_range').
  final String code;

  @override
  List<Object?> get props => [field, code];
}

// ── Booking-specific ──────────────────────────────────────────────────────────

/// The requested slot was booked by another student between the user viewing
/// and submitting the booking form.
final class SlotUnavailableFailure extends QuranSessionsFailure {
  const SlotUnavailableFailure(this.slotId);

  final String slotId;

  @override
  List<Object?> get props => [slotId];
}

/// A booking could not be created because of a policy conflict (e.g. the
/// student already has a session at the same time).
final class BookingConflictFailure extends QuranSessionsFailure {
  const BookingConflictFailure();
}

// ── Storage ───────────────────────────────────────────────────────────────────

final class CacheFailure extends QuranSessionsFailure {
  const CacheFailure();
}

// ── Payment ───────────────────────────────────────────────────────────────────

/// The card or payment method was declined by the payment gateway.
/// Mapped from [ChargeDeclinedFailure] at the BLoC boundary.
final class PaymentDeclinedFailure extends QuranSessionsFailure {
  const PaymentDeclinedFailure();
}

/// The user dismissed the payment sheet without completing.
/// Mapped from [ChargeCancelledFailure] at the BLoC boundary.
final class PaymentCancelledFailure extends QuranSessionsFailure {
  const PaymentCancelledFailure();
}

/// The payment gateway returned an unexpected error.
/// Mapped from [GatewayFailure] at the BLoC boundary.
final class PaymentProviderFailure extends QuranSessionsFailure {
  const PaymentProviderFailure();
}

// ── Catch-all ─────────────────────────────────────────────────────────────────

final class UnknownFailure extends QuranSessionsFailure {
  const UnknownFailure();
}
