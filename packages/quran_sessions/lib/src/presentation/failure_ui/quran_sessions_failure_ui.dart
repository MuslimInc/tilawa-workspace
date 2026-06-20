import 'package:flutter/widgets.dart';

import '../../domain/failures/quran_sessions_failure.dart';

/// Extension that converts a typed [QuranSessionsFailure] into a
/// user-facing, localised message.
///
/// The **default** implementation returns English developer-facing strings so
/// the package is self-contained during development.
///
/// The host app MUST override this by defining its own extension in the
/// app's l10n layer:
///
/// ```dart
/// // In apps/tilawa/lib/core/extensions/failure_l10n.dart
/// extension TilawaFailureL10n on QuranSessionsFailure {
///   @override
///   String toLocalizedMessage(BuildContext context) => switch (this) {
///     NetworkFailure()         => context.l10n.errorNetwork,
///     TimeoutFailure()         => context.l10n.errorTimeout,
///     ServerFailure(statusCode: 401) ||
///     UnauthorizedFailure()    => context.l10n.errorUnauthorized,
///     ServerFailure()          => context.l10n.errorServer,
///     NotFoundFailure()        => context.l10n.errorNotFound,
///     ValidationFailure(:final field) =>
///         context.l10n.errorValidation(field),
///     SlotUnavailableFailure() => context.l10n.errorSlotUnavailable,
///     BookingConflictFailure() => context.l10n.errorBookingConflict,
///     CacheFailure()           => context.l10n.errorCache,
///     UnknownFailure()         => context.l10n.errorUnknown,
///   };
/// }
/// ```
///
/// Screens call: `state.failure.toLocalizedMessage(context)`
/// Neither BLoCs nor states ever produce a String.
extension QuranSessionsFailureUi on QuranSessionsFailure {
  String toLocalizedMessage(BuildContext context) => switch (this) {
    NetworkFailure() => 'No internet connection.',
    TimeoutFailure() => 'The request timed out.',
    ServerFailure(statusCode: final c) when c == 401 =>
      'Session expired. Please sign in again.',
    ServerFailure(statusCode: final c) when c == 403 =>
      'You do not have permission to perform this action.',
    ServerFailure() => 'Something went wrong on the server.',
    UnauthorizedFailure() => 'You are not authorised.',
    NotFoundFailure(resourceType: final t) => '$t not found.',
    ValidationFailure(field: final f, code: final c) =>
      'Validation failed: $f ($c).',
    SlotUnavailableFailure() =>
      'This slot is no longer available. Please choose another.',
    BookingConflictFailure() => 'You already have a session at this time.',
    PaymentDeclinedFailure() =>
      'Your payment was declined. Please try another method.',
    PaymentCancelledFailure() => 'Payment was cancelled.',
    PaymentProviderFailure() =>
      'Payment could not be processed. Please try again.',
    CacheFailure() => 'Could not read local data.',
    UnknownFailure() => 'An unexpected error occurred.',
  };
}
